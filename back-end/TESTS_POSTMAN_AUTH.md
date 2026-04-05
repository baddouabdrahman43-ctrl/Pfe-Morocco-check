# Tests Postman - MoroccoCheck Auth API

## Collection Postman : "MoroccoCheck Auth"

### Variables d'environnement
- `{{baseUrl}}` = `http://localhost:5000`

---

## TEST 1 - Register User Success

**Description** : Enregistrement d'un nouvel utilisateur avec succès

**Method** : `POST`
**URL** : `{{baseUrl}}/api/auth/register`

**Headers** :
```
Content-Type: application/json
```

**Body (JSON)** :
```json
{
  "name": "Ahmed Tazi",
  "email": "ahmed@test.com",
  "password": "password123"
}
```

**Expected Response** :
- **Status** : `201 Created`
- **Body** :
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "name": "Ahmed Tazi",
      "email": "ahmed@test.com",
      "role": "tourist",
      "points": 0,
      "level": "Bronze"
    }
  },
  "message": "Inscription réussie"
}
```

**Curl Command** :
```bash
curl -X POST "http://localhost:5000/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Ahmed Tazi",
    "email": "ahmed@test.com",
    "password": "password123"
  }'
```

---

## TEST 2 - Register Duplicate Email

**Description** : Tentative d'enregistrement avec un email déjà utilisé

**Method** : `POST`
**URL** : `{{baseUrl}}/api/auth/register`

**Headers** :
```
Content-Type: application/json
```

**Body (JSON)** :
```json
{
  "name": "Ahmed Tazi",
  "email": "ahmed@test.com",
  "password": "password123"
}
```

**Expected Response** :
- **Status** : `400 Bad Request`
- **Body** :
```json
{
  "success": false,
  "message": "Email déjà utilisé"
}
```

**Curl Command** :
```bash
curl -X POST "http://localhost:5000/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Ahmed Tazi",
    "email": "ahmed@test.com",
    "password": "password123"
  }'
```

---

## TEST 3 - Register Invalid Email

**Description** : Tentative d'enregistrement avec un format d'email invalide

**Method** : `POST`
**URL** : `{{baseUrl}}/api/auth/register`

**Headers** :
```
Content-Type: application/json
```

**Body (JSON)** :
```json
{
  "name": "Test",
  "email": "invalid",
  "password": "pass123"
}
```

**Expected Response** :
- **Status** : `400 Bad Request`
- **Body** :
```json
{
  "success": false,
  "message": "Validation échouée",
  "errors": [
    "Veuillez fournir un email valide"
  ]
}
```

**Curl Command** :
```bash
curl -X POST "http://localhost:5000/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test",
    "email": "invalid",
    "password": "pass123"
  }'
```

---

## TEST 4 - Register Short Password

**Description** : Tentative d'enregistrement avec un mot de passe trop court

**Method** : `POST`
**URL** : `{{baseUrl}}/api/auth/register`

**Headers** :
```
Content-Type: application/json
```

**Body (JSON)** :
```json
{
  "name": "Test",
  "email": "test@test.com",
  "password": "123"
}
```

**Expected Response** :
- **Status** : `400 Bad Request`
- **Body** :
```json
{
  "success": false,
  "message": "Validation échouée",
  "errors": [
    "Le mot de passe doit contenir au moins 6 caractères"
  ]
}
```

**Curl Command** :
```bash
curl -X POST "http://localhost:5000/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test",
    "email": "test@test.com",
    "password": "123"
  }'
```

---

## Notes de Test

### Points importants à vérifier :
1. **Token JWT** : Vérifier que le token est bien généré et a une durée de 7 jours
2. **Sécurité** : Le mot de passe ne doit jamais apparaître dans les réponses
3. **Messages d'erreur** : Les messages doivent être génériques pour éviter l'énumération d'utilisateurs
4. **Validation** : Tous les champs doivent être validés côté serveur
5. **Base de données** : Vérifier que les utilisateurs sont bien insérés en base de données

### Prérequis :
- Le serveur doit être démarré sur le port 5000
- La base de données doit être accessible et configurée
- Les variables d'environnement doivent être définies (JWT_SECRET, etc.)

### Ordre de test recommandé :
1. TEST 1 : Enregistrement réussi (créer un utilisateur)
2. TEST 2 : Email dupliqué (vérifier la contrainte d'unicité)
3. TEST 3 : Email invalide (vérifier la validation)
4. TEST 4 : Mot de passe court (vérifier la validation)

---

## TEST 5 - Login Success

**Description** : Connexion réussie d'un utilisateur existant

**Method** : `POST`
**URL** : `{{baseUrl}}/api/auth/login`

**Headers** :
```
Content-Type: application/json
```

**Body (JSON)** :
```json
{
  "email": "ahmed@test.com",
  "password": "password123"
}
```

**Expected Response** :
- **Status** : `200 OK`
- **Body** :
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "name": "Ahmed Tazi",
      "email": "ahmed@test.com",
      "role": "tourist",
      "points": 0,
      "level": "Bronze",
      "avatar_url": null,
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-01T00:00:00.000Z"
    }
  },
  "message": "Connexion réussie"
}
```

**Postman Test Script** :
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has success true", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.success).to.eql(true);
});

pm.test("Response has token", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.data.token).to.be.a('string');
    pm.expect(jsonData.data.token).to.not.be.empty;
});

pm.test("Response has user data", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.data.user).to.have.property('id');
    pm.expect(jsonData.data.user).to.have.property('name');
    pm.expect(jsonData.data.user).to.have.property('email');
    pm.expect(jsonData.data.user).to.have.property('role');
});

// Save token for subsequent tests
pm.test("Save token to environment", function () {
    const jsonData = pm.response.json();
    pm.environment.set("authToken", jsonData.data.token);
});
```

**Curl Command** :
```bash
curl -X POST "http://localhost:5000/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "ahmed@test.com",
    "password": "password123"
  }'
```

---

## TEST 6 - Login Invalid Credentials

**Description** : Tentative de connexion avec des identifiants invalides

**Method** : `POST`
**URL** : `{{baseUrl}}/api/auth/login`

**Headers** :
```
Content-Type: application/json
```

**Body (JSON)** :
```json
{
  "email": "wrong@test.com",
  "password": "wrong"
}
```

**Expected Response** :
- **Status** : `401 Unauthorized`
- **Body** :
```json
{
  "success": false,
  "message": "Email ou mot de passe incorrect"
}
```

**Postman Test Script** :
```javascript
pm.test("Status code is 401", function () {
    pm.response.to.have.status(401);
});

pm.test("Response has success false", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.success).to.eql(false);
});

pm.test("Response has error message", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.message).to.eql("Email ou mot de passe incorrect");
});
```

**Curl Command** :
```bash
curl -X POST "http://localhost:5000/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "wrong@test.com",
    "password": "wrong"
  }'
```

---

## TEST 7 - Get Profile (Protected)

**Description** : Récupération du profil utilisateur avec token valide

**Method** : `GET`
**URL** : `{{baseUrl}}/api/auth/profile`

**Headers** :
```
Authorization: Bearer {{authToken}}
```

**Expected Response** :
- **Status** : `200 OK`
- **Body** :
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "name": "Ahmed Tazi",
      "email": "ahmed@test.com",
      "role": "tourist",
      "points": 0,
      "level": "Bronze",
      "avatar_url": null,
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-01T00:00:00.000Z"
    }
  }
}
```

**Postman Test Script** :
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has success true", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.success).to.eql(true);
});

pm.test("Response has user data", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.data.user).to.have.property('id');
    pm.expect(jsonData.data.user).to.have.property('name');
    pm.expect(jsonData.data.user).to.have.property('email');
    pm.expect(jsonData.data.user).to.have.property('role');
    pm.expect(jsonData.data.user).to.have.property('points');
    pm.expect(jsonData.data.user).to.have.property('level');
});

pm.test("Password is not included", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.data.user).to.not.have.property('password');
});
```

**Curl Command** :
```bash
curl -X GET "http://localhost:5000/api/auth/profile" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

---

## TEST 8 - Get Profile Without Token

**Description** : Tentative d'accès au profil sans token d'authentification

**Method** : `GET`
**URL** : `{{baseUrl}}/api/auth/profile`

**Headers** : (aucun)

**Expected Response** :
- **Status** : `401 Unauthorized`
- **Body** :
```json
{
  "success": false,
  "message": "Token manquant"
}
```

**Postman Test Script** :
```javascript
pm.test("Status code is 401", function () {
    pm.response.to.have.status(401);
});

pm.test("Response has success false", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.success).to.eql(false);
});

pm.test("Response has missing token message", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.message).to.eql("Token manquant");
});
```

**Curl Command** :
```bash
curl -X GET "http://localhost:5000/api/auth/profile"
```

---

## TEST 9 - Update Profile

**Description** : Mise à jour du profil utilisateur avec token valide

**Method** : `PUT`
**URL** : `{{baseUrl}}/api/auth/profile`

**Headers** :
```
Authorization: Bearer {{authToken}}
Content-Type: application/json
```

**Body (JSON)** :
```json
{
  "name": "Ahmed Tazi Updated",
  "avatar_url": "https://example.com/avatar.jpg"
}
```

**Expected Response** :
- **Status** : `200 OK`
- **Body** :
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "name": "Ahmed Tazi Updated",
      "email": "ahmed@test.com",
      "role": "tourist",
      "points": 0,
      "level": "Bronze",
      "avatar_url": "https://example.com/avatar.jpg",
      "created_at": "2024-01-01T00:00:00.000Z",
      "updated_at": "2024-01-01T00:00:00.000Z"
    }
  },
  "message": "Profil mis à jour avec succès"
}
```

**Postman Test Script** :
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has success true", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.success).to.eql(true);
});

pm.test("Response has updated user data", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.data.user.name).to.eql("Ahmed Tazi Updated");
    pm.expect(jsonData.data.user.avatar_url).to.eql("https://example.com/avatar.jpg");
});

pm.test("Email remains unchanged", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.data.user.email).to.eql("ahmed@test.com");
});

pm.test("Password is not included", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.data.user).to.not.have.property('password');
});
```

**Curl Command** :
```bash
curl -X PUT "http://localhost:5000/api/auth/profile" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Ahmed Tazi Updated",
    "avatar_url": "https://example.com/avatar.jpg"
  }'
```

---

## TEST 10 - Update Profile with Duplicate Email

**Description** : Tentative de mise à jour avec un email déjà utilisé

**Method** : `PUT`
**URL** : `{{baseUrl}}/api/auth/profile`

**Headers** :
```
Authorization: Bearer {{authToken}}
Content-Type: application/json
```

**Body (JSON)** :
```json
{
  "email": "existing@test.com"
}
```

**Expected Response** :
- **Status** : `400 Bad Request`
- **Body** :
```json
{
  "success": false,
  "message": "Email déjà utilisé"
}
```

**Postman Test Script** :
```javascript
pm.test("Status code is 400", function () {
    pm.response.to.have.status(400);
});

pm.test("Response has success false", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.success).to.eql(false);
});

pm.test("Response has duplicate email message", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.message).to.eql("Email déjà utilisé");
});
```

**Curl Command** :
```bash
curl -X PUT "http://localhost:5000/api/auth/profile" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "email": "existing@test.com"
  }'
```

---

## Script d'automatisation des tests

### Collection Runner Script

**Pré-requis** : Créer une collection "MoroccoCheck Auth" avec toutes les requêtes ci-dessus dans l'ordre.

**Variables d'environnement** :
- `baseUrl` : `http://localhost:5000`
- `authToken` : (sera automatiquement rempli par le test 5)

### Script de test complet (Postman Collection Runner)

```javascript
// Script à ajouter dans le "Pre-request Script" de la collection
pm.globals.set("testUserEmail", "ahmed@test.com");
pm.globals.set("testUserPassword", "password123");
pm.globals.set("testUserName", "Ahmed Tazi");
```

### Script de validation global (dans le "Tests" de chaque requête)

```javascript
// Script à ajouter dans le "Tests" de chaque requête pour une validation uniforme
pm.test("Response time is less than 2000ms", function () {
    pm.expect(pm.response.responseTime).to.be.below(2000);
});

pm.test("Response has valid JSON", function () {
    pm.expect(() => JSON.parse(pm.response.text())).to.not.throw();
});

pm.test("Response has success field", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('success');
    pm.expect(jsonData.success).to.be.a('boolean');
});
```

### Ordre d'exécution recommandé :

1. **TEST 1** : Register User Success (créer un utilisateur de test)
2. **TEST 2** : Register Duplicate Email (vérifier unicité)
3. **TEST 3** : Register Invalid Email (vérifier validation)
4. **TEST 4** : Register Short Password (vérifier validation)
5. **TEST 5** : Login Success (se connecter et sauvegarder le token)
6. **TEST 6** : Login Invalid Credentials (vérifier sécurité)
7. **TEST 7** : Get Profile (vérifier accès protégé)
8. **TEST 8** : Get Profile Without Token (vérifier protection)
9. **TEST 9** : Update Profile (vérifier mise à jour)
10. **TEST 10** : Update Profile with Duplicate Email (vérifier unicité email)

### Commandes pour exécuter les tests via Newman (CLI)

```bash
# Installer Newman si ce n'est pas déjà fait
npm install -g newman

# Exécuter la collection Postman
newman run "MoroccoCheck Auth.postman_collection.json" \
  -e "MoroccoCheck.postman_environment.json" \
  --reporters cli,html \
  --reporter-html-export "test-results.html"

# Exécuter avec variables globales
newman run "MoroccoCheck Auth.postman_collection.json" \
  -g "globals.json" \
  --reporters cli,html \
  --reporter-html-export "test-results.html"
```

### Points de validation importants :

1. **Sécurité** : Vérifier que les tokens sont bien requis et valides
2. **Validation** : Tous les champs doivent être correctement validés
3. **Unicité** : Les emails doivent être uniques dans la base de données
4. **Sécurité des données** : Les mots de passe ne doivent jamais apparaître dans les réponses
5. **Permissions** : Seul l'utilisateur authentifié peut accéder à son propre profil
6. **Robustesse** : Toutes les erreurs doivent être correctement gérées et retournées
