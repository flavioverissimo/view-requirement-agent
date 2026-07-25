# Requirement Interpretation Application

This repository contains two parts:

- `api/`: a FastAPI back-end that receives a view name and a natural-language requirement, runs the interpretation workflow, and returns a structured JSON response.
- `frontend/`: a Next.js web interface that lets a user choose a view, write a requirement in plain language, send it to the API, and read the formatted result in the browser.

The project also includes helper scripts in the repository root to make setup and startup easier for non-technical users:

- `setup.ps1` and `setup.sh`: prepare the local environment only.
- `start.ps1` and `start.sh`: prepare the local environment and then start both the back-end and the front-end.

## Quick Start

Use this section if you want the simplest possible setup.

Before you start, make sure the file `api/.env` contains the required OpenAI settings:

- `OPENAI_API_KEY`
- `OPENAI_MODEL`

If those values are missing, the back-end cannot start.

### Windows Quick Start

If you want the application to prepare everything and open the required terminals automatically:

1. Open the `application` folder in File Explorer.
2. Locate the file `start.ps1`.
3. Right-click `start.ps1`.
4. Choose `Run with PowerShell`.

If Windows blocks the script or closes the window too quickly, use the terminal method below instead:

1. Open the Start menu.
2. Search for `PowerShell`.
3. Open `Windows PowerShell`.
4. Run the commands below:

```powershell
cd C:\path\to\application
powershell -ExecutionPolicy Bypass -File .\start.ps1
```

What this script does:

1. Checks whether Python, Node.js, and npm are installed.
2. Shows download links if something is missing.
3. Prepares the Python virtual environment in `api/.venv` if needed.
4. Installs missing Python dependencies if needed.
5. Installs missing front-end dependencies if needed.
6. Opens one terminal for the back-end and one terminal for the front-end.

If you only want to prepare the environment, but not start the application automatically, run:

```powershell
cd C:\path\to\application
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

### macOS Quick Start

If you want the application to prepare everything and start both services automatically:

1. Open the `Terminal` application.
2. Move to the project folder:

```bash
cd /path/to/application
```

3. Run:

```bash
sh start.sh
```

What this script does:

1. Checks whether Python, Node.js, and npm are installed.
2. Shows download links if something is missing.
3. Prepares the Python virtual environment in `api/.venv` if needed.
4. Installs missing Python dependencies if needed.
5. Installs missing front-end dependencies if needed.
6. Opens or starts the back-end and front-end processes.

If you only want to prepare the environment, but not start the application automatically, run:

```bash
cd /path/to/application
sh setup.sh
```

### Linux Quick Start

On Linux, use the same terminal-based flow:

1. Open a terminal.
2. Move to the project folder:

```bash
cd /path/to/application
```

3. Run:

```bash
sh start.sh
```

If you only want to prepare the environment, but not start the application automatically, run:

```bash
cd /path/to/application
sh setup.sh
```

On some Linux systems, `start.sh` may open graphical terminal windows. On systems without a supported graphical terminal, it may keep both services running from the current shell instead.

## Manual Configuration

Use this section if you want to create the environment yourself without helper scripts.

### Manual Python Setup for the API

1. Open a terminal.
2. Move to the `api` folder.
3. Create a Python virtual environment.
4. Activate it.
5. Install the Python dependencies.

#### Windows

```powershell
cd C:\path\to\application\api
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

If `python` is not available on your system, try:

```powershell
py -3 -m venv .venv
.\.venv\Scripts\Activate.ps1
py -3 -m pip install -r requirements.txt
```

After the installation is complete, start the API with:

```powershell
uvicorn main:app --reload
```

#### macOS and Linux

```bash
cd /path/to/application/api
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r requirements.txt
```

If your system uses `python` instead of `python3`, you can replace `python3` with `python`.

After the installation is complete, start the API with:

```bash
uvicorn main:app --reload
```

### Manual JavaScript Setup for the Front-End

1. Open a new terminal.
2. Move to the `frontend` folder.
3. Install the Node.js dependencies.
4. Start the Next.js development server.

#### Windows

```powershell
cd C:\path\to\application\frontend
npm install
npm run dev
```

#### macOS and Linux

```bash
cd /path/to/application/frontend
npm install
npm run dev
```

### Front-End API Target

The front-end expects the API at:

```text
http://localhost:8000/api/v1
```

If you want to use a different API URL, create or edit `frontend/.env` and set:

```env
NEXT_PUBLIC_API_BASE_URL=http://localhost:8000/api/v1
```

Replace the URL with your own API address if necessary.

## Running the Application Manually

If you prepared everything manually, the typical workflow is:

1. Start the back-end first.
2. Start the front-end second.
3. Open the browser and access the front-end URL shown by Next.js, usually:

```text
http://localhost:3000
```

## Troubleshooting

### Python or Node.js is missing

The helper scripts will stop and show download links if Python or Node.js is not installed.

Official download pages:

- Python: https://www.python.org/downloads/
- Node.js: https://nodejs.org/en/download

### The PowerShell script is blocked

If Windows does not allow the script to run from File Explorer, open PowerShell and use:

```powershell
cd C:\path\to\application
powershell -ExecutionPolicy Bypass -File .\start.ps1
```

or:

```powershell
cd C:\path\to\application
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

### The browser opens the front-end but requests fail

Make sure:

1. The back-end is running.
2. The file `api/.env` contains valid OpenAI settings.
3. The front-end is pointing to the correct API URL.

### The environment already exists

The helper scripts are idempotent:

- they do not recreate the Python virtual environment if `api/.venv` already exists
- they do not reinstall dependencies if the existing installation still matches the current dependency files
