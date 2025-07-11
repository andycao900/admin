## 📘 `admin` – Phoenix Admin Web App

This is a Phoenix web application named **`admin`**, built to manage users and provide a foundation for internal tooling. It includes basic user CRUD functionality and supports authentication via Auth0 using Ueberauth.

---

### 🚀 Features

* Phoenix 1.7+ with Vite + TailwindCSS
* PostgreSQL with Ecto
* User CRUD interface (`email` field)
* Authentication via Auth0 using Ueberauth
* Live reload, formatting, and developer-friendly setup

---

### 🛠 Requirements

* Elixir >= 1.14
* Erlang/OTP >= 25
* PostgreSQL
* Node.js >= 18 (for assets)
* `npm` or `pnpm`

---

### 🧪 Setup Instructions

```bash
# Clone the repo
git clone git@github.com:andycao900/admin.git
cd admin

# Install Elixir dependencies
mix deps.get

# Install JS dependencies
cd assets && npm install && cd ..

# Set up the database
mix ecto.setup

# Start the server
mix phx.server
```

Visit: [http://localhost:4000](http://localhost:4000)

---

### 🔐 Auth0 Integration

Set the following environment variables for Ueberauth + Auth0:

```bash
export AUTH0_DOMAIN=your-domain.auth0.com
export AUTH0_CLIENT_ID=your-client-id
export AUTH0_CLIENT_SECRET=your-client-secret
```

Then go to:

```
http://localhost:4000/auth/auth0
```

---

### 📁 Project Structure Highlights

* `lib/admin/` – Application logic (contexts, Ecto, etc.)
* `lib/admin_web/` – Web layer (controllers, views, templates)
* `assets/` – Frontend assets (Tailwind, Vite, JS)

---

### 📦 Dev Tips

* Format code: `mix format`
* View routes: `mix phx.routes`
* Tailwind config: `assets/tailwind.config.js`
* Run tests: `mix test`

---

### 📝 License

MIT License — see `LICENSE` file.

---

Let me know if you'd like to add badges, CI setup, Docker support, or a `CONTRIBUTING.md` guide.
