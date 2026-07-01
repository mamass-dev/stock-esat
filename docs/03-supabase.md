# 3bis — Base Supabase (schéma SQL, sécurité RLS, triggers)

> Remplace `03-airtable.md`. Base de vérité = **Postgres/Supabase**. Le stock est maintenu par un **trigger SQL** (équivalent de l'automation A1). L'app Flutter parle **directement** à Supabase (plus de proxy) grâce à RLS.

## 3bis.1 Modèle de sécurité (le point clé qui supprime le proxy)

- L'app embarque la **clé `anon`** de Supabase (publique, non secrète). Elle *peut* être extraite de l'APK — **et ce n'est pas grave**, car **RLS** limite ce qu'elle autorise à des opérations sûres :
  - ✅ lire les référentiels (produits, catégories, emplacements, missions)
  - ✅ **insérer** des `mouvements` (l'opérateur ne fait que ça)
  - ❌ modifier un stock, un seuil, un prix (impossible via l'app)
- Le **stock ne se met jamais à jour à la main** : un trigger `SECURITY DEFINER` s'en charge à l'insertion d'un mouvement.
- **Opérateurs** : identifiés par un **PIN** (hashé, vérifié par une fonction `login_operateur`). Le PIN sert à *estampiller* qui agit et à déverrouiller l'écran Responsable.
- **Responsable** : actions sensibles (éditer seuils, créer missions, exporter) → soit via **Supabase Studio**, soit via un **compte Supabase Auth** (email+mot de passe) dans un écran admin, soit via une **Edge Function** protégée par PIN responsable.

> Différence fondamentale avec Airtable : là-bas, la clé API donne un accès **total en écriture** → proxy obligatoire. Ici la clé anon est **bridée par RLS** → pas de proxy.

## 3bis.2 Schéma SQL complet

```sql
-- Extensions utiles
create extension if not exists pgcrypto;      -- hash PIN (crypt/gen_salt)

-- ─────────────── Référentiels ───────────────
create table categories (
  id          uuid primary key default gen_random_uuid(),
  nom         text not null,
  picto       text,
  couleur     text,
  ordre       int default 0,
  cree_le     timestamptz default now()
);

create table emplacements (
  id          uuid primary key default gen_random_uuid(),
  code        text unique not null,          -- A01, B15…
  libelle     text,
  zone        text,
  reserve     text default 'Réserve principale',
  cree_le     timestamptz default now()
);

create table fournisseurs (
  id            uuid primary key default gen_random_uuid(),
  nom           text not null,
  contact       text,
  email         text,
  telephone     text,
  delai_jours   int,
  cree_le       timestamptz default now()
);

create table operateurs (
  id          uuid primary key default gen_random_uuid(),
  nom         text not null,
  pin_hash    text not null,                 -- jamais le PIN en clair
  badge_uid   text,
  role        text not null default 'operateur'
              check (role in ('operateur','responsable','admin')),
  photo_url   text,
  actif       boolean default true,
  reserve     text default 'Réserve principale',
  cree_le     timestamptz default now()
);

-- ─────────────── Produits (stock courant) ───────────────
create table produits (
  id                uuid primary key default gen_random_uuid(),
  ref               text unique not null,     -- payload QR : "P:DET-SOL-5L"
  nom               text not null,
  photo_url         text,
  categorie_id      uuid references categories(id),
  emplacement_id    uuid references emplacements(id),
  fournisseur_id    uuid references fournisseurs(id),
  unite             text,                      -- bidon, sac, carton…
  conditionnement   int,
  prix_unitaire_ht  numeric(10,2) default 0,
  stock_courant     int not null default 0,    -- écrit par le trigger, pas par l'app
  seuil_mini        int default 0,
  seuil_rupture     int default 0,
  seuil_cible       int default 0,
  actif             boolean default true,
  reserve           text default 'Réserve principale',
  cree_le           timestamptz default now(),
  modifie_le        timestamptz default now()
);

-- Statut couleur : calculé à la lecture (vue) pour rester simple
create view v_produits_statut as
select p.*,
  case
    when p.stock_courant <= p.seuil_rupture then '🔴 Rupture'
    when p.stock_courant <= p.seuil_mini    then '🟠 Faible'
    else '🟢 OK'
  end as statut,
  (p.stock_courant * p.prix_unitaire_ht) as valeur_stock
from produits p;

-- ─────────────── Mouvements (journal) ───────────────
create table mouvements (
  id            uuid primary key default gen_random_uuid(),
  type          text not null check (type in ('Entrée','Sortie','Correction','Inventaire')),
  produit_id    uuid not null references produits(id),
  quantite      int not null check (quantite > 0),  -- le signe vient du type
  stock_avant   int,                                 -- rempli par le trigger
  stock_apres   int,                                 -- rempli par le trigger
  operateur_id  uuid references operateurs(id),
  emplacement_id uuid references emplacements(id),
  mission_id    uuid,                                -- fk ajoutée plus bas
  client_key    text unique,                         -- idempotence offline (UUID app)
  source        text default 'Scan',
  commentaire   text,
  cree_le       timestamptz default now()
);

-- ─────────────── Missions ───────────────
create table missions (
  id            uuid primary key default gen_random_uuid(),
  nom           text not null,
  description   text,
  assignee_id   uuid references operateurs(id),
  statut        text default 'À faire' check (statut in ('À faire','En cours','Terminée','Annulée')),
  type_mouvement text default 'Sortie',
  date_prevue   date,
  creee_par     uuid references operateurs(id),
  cree_le       timestamptz default now()
);
alter table mouvements
  add constraint fk_mvt_mission foreign key (mission_id) references missions(id);

create table lignes_missions (
  id               uuid primary key default gen_random_uuid(),
  mission_id       uuid not null references missions(id) on delete cascade,
  ordre            int not null,
  produit_id       uuid not null references produits(id),
  quantite_prevue  int not null,
  quantite_servie  int default 0,
  statut           text default 'En attente'
                   check (statut in ('En attente','Servie','Passée'))
);

-- ─────────────── Alertes ───────────────
create table alertes (
  id                  uuid primary key default gen_random_uuid(),
  produit_id          uuid not null references produits(id),
  type                text check (type in ('Sous seuil','Rupture')),
  stock_declenchement int,
  statut              text default 'Ouverte' check (statut in ('Ouverte','Commandée','Résolue')),
  cree_le             timestamptz default now()
);

-- ─────────────── Inventaires ───────────────
create table inventaires (
  id                uuid primary key default gen_random_uuid(),
  produit_id        uuid not null references produits(id),
  quantite_comptee  int not null,
  stock_theorique   int,
  operateur_id      uuid references operateurs(id),
  ajuste            boolean default false,
  cree_le           timestamptz default now()
);
```

## 3bis.3 Le trigger « stock » (= automation A1)

```sql
-- Met à jour le stock du produit à chaque mouvement inséré,
-- et remplit stock_avant / stock_apres. SECURITY DEFINER => contourne RLS proprement.
create or replace function maj_stock_apres_mouvement()
returns trigger
language plpgsql
security definer
as $$
declare
  v_stock_avant int;
  v_delta int;
begin
  select stock_courant into v_stock_avant
  from produits where id = new.produit_id for update;

  v_delta := case when new.type = 'Entrée' then new.quantite
                  else -new.quantite end;

  update produits
    set stock_courant = v_stock_avant + v_delta,
        modifie_le = now()
  where id = new.produit_id;

  new.stock_avant := v_stock_avant;
  new.stock_apres := v_stock_avant + v_delta;
  return new;
end;
$$;

create trigger trg_maj_stock
  before insert on mouvements
  for each row execute function maj_stock_apres_mouvement();
```

## 3bis.4 Alertes automatiques (= automation A2/A3)

```sql
create or replace function gerer_alertes()
returns trigger language plpgsql security definer as $$
declare v_p produits%rowtype;
begin
  select * into v_p from produits where id = new.produit_id;
  -- sous seuil / rupture -> créer une alerte si aucune ouverte
  if v_p.stock_courant <= v_p.seuil_mini then
    if not exists (select 1 from alertes
                   where produit_id = v_p.id and statut = 'Ouverte') then
      insert into alertes(produit_id, type, stock_declenchement)
      values (v_p.id,
              case when v_p.stock_courant <= v_p.seuil_rupture
                   then 'Rupture' else 'Sous seuil' end,
              v_p.stock_courant);
    end if;
  else
    -- repassé au-dessus -> on résout les alertes ouvertes
    update alertes set statut = 'Résolue'
    where produit_id = v_p.id and statut = 'Ouverte';
  end if;
  return new;
end; $$;

create trigger trg_alertes
  after insert on mouvements
  for each row execute function gerer_alertes();
```

## 3bis.5 Connexion opérateur par PIN (sans exposer les hash)

```sql
-- Vérifie un PIN et renvoie l'opérateur correspondant (sans le hash).
create or replace function login_operateur(p_pin text)
returns table(id uuid, nom text, role text, photo_url text)
language plpgsql security definer as $$
begin
  return query
  select o.id, o.nom, o.role, o.photo_url
  from operateurs o
  where o.actif
    and o.pin_hash = crypt(p_pin, o.pin_hash);   -- comparaison bcrypt
end; $$;

-- Créer un opérateur (à faire côté Studio / admin) :
-- insert into operateurs(nom, pin_hash, role)
-- values ('Karim', crypt('1234', gen_salt('bf')), 'operateur');
```
> ⚠️ Un PIN à 4 chiffres est faible par nature (10 000 combinaisons). Acceptable pour un usage kiosque interne, mais : limite le débit d'appels à `login_operateur`, et ne repose pas la sécurité *critique* dessus — la vraie barrière est la RLS.

## 3bis.6 Politiques RLS (ce qui rend l'app directe et sûre)

```sql
alter table produits      enable row level security;
alter table categories    enable row level security;
alter table emplacements  enable row level security;
alter table mouvements    enable row level security;
alter table missions      enable row level security;
alter table lignes_missions enable row level security;
alter table alertes       enable row level security;
-- operateurs : PAS d'accès direct (on passe par login_operateur)
alter table operateurs    enable row level security;   -- aucune policy = tout bloqué au client

-- Lecture des référentiels pour la clé anon (l'app)
create policy lecture_produits    on produits     for select to anon using (true);
create policy lecture_categories  on categories   for select to anon using (true);
create policy lecture_emplacements on emplacements for select to anon using (true);
create policy lecture_missions    on missions     for select to anon using (true);
create policy lecture_lignes      on lignes_missions for select to anon using (true);

-- L'app peut UNIQUEMENT insérer des mouvements (pas update/delete, pas de maj stock)
create policy insert_mouvements   on mouvements   for insert to anon with check (true);
create policy lecture_mouvements  on mouvements   for select to anon using (true);

-- Alertes : lecture seule côté app
create policy lecture_alertes     on alertes      for select to anon using (true);

-- Servir une ligne de mission (update quantite_servie/statut) — tolérable en anon,
-- ou à restreindre via Edge Function si besoin de durcir.
create policy update_lignes       on lignes_missions for update to anon using (true) with check (true);
```

- **Éditer produits / seuils / prix / créer missions** = **aucune policy anon** → impossible depuis l'app. Ces actions se font via **Studio** ou un **compte responsable authentifié** (`authenticated`), pour lequel on ajoutera des policies dédiées :
```sql
create policy resp_ecrit_produits on produits
  for all to authenticated using (true) with check (true);
```

## 3bis.7 Storage (photos produits)
- Bucket Supabase Storage `produits-photos` (public en lecture).
- `produits.photo_url` = URL publique. Upload depuis Studio (responsable) ou écran admin.
- Avantage vs Airtable : pas de limite d'attachements, CDN intégré, URLs stables.

## 3bis.8 Export Excel & tableau de bord
- **Export** : une **Edge Function** `/export` (Deno) qui lit Postgres et génère le `.xlsx` mis en forme (lib `exceljs` via esm) → inventaire, historique, à commander, conso, valorisation. Déclenchée depuis l'écran Responsable.
- **Cockpit** : des **vues SQL** (ex. `v_conso_mensuelle`, `v_top_produits`, `v_valorisation`) lues par l'app :
```sql
create view v_conso_mensuelle as
select produit_id,
       date_trunc('month', cree_le) as mois,
       sum(quantite) as sorties
from mouvements where type = 'Sortie'
group by produit_id, date_trunc('month', cree_le);
```
- **Sauvegardes** : Supabase fait des backups automatiques (plan Pro : PITR). En plus, `pg_dump` planifié possible.
```

## 3bis.9 Ce qui change vs le plan Airtable
| Élément | Airtable | Supabase |
|---|---|---|
| Proxy backend | Obligatoire | **Supprimé** (RLS + anon) |
| Logique stock | Automation script | **Trigger SQL** (plus fiable/rapide) |
| Auth | Hash côté proxy | `login_operateur` RPC + RLS |
| Admin responsable | Grille native | Studio Supabase ou écran admin (à coder) |
| Export Excel | Automation/script | Edge Function |
| Photos | Attachments (limités) | Storage + CDN |
| Offline / idempotence | `client_key` custom | `client_key unique` (idempotence native en base) |
