![Application preview](docs/images/application-preview.png)

# View Requirement Agent

> [!IMPORTANT]
> ## Try the Application Online
>
> You can test the web application at:
>
> [![Application preview](docs/images/application-preview.png)](https://view-requirement-agent.vercel.app/)
>
> The hosted application will remain available only until **August 25, 2026, at 12:00 AM**.
>
> After this date, to use the application, you will need to download the repository and prepare the local environment by following the instructions provided in the respective README files:
>
> - [application/README.md](application/README.md) for the web application
> - [view_agent/README.md](view_agent/README.md) for the command-line application

This repository contains two ways to use the same requirement interpretation workflow:

- `application/`: a complete web application with a front-end and a back-end API
- `view_agent/`: a command-line application focused on terminal usage and automation

Both options are designed to interpret natural-language quality requirements for supported views and return a structured result.

## Repository Overview

### `application/`

`application/` is the best choice for people who want a more guided and visual experience.

It includes:

- a `frontend/` built with Next.js
- an `api/` built with FastAPI
- setup and start scripts to help prepare and launch the application

With this option, the user can open a browser, choose a view, type a requirement in plain language, submit it, and read the formatted result on screen.

Use `application/` when:

- you want a graphical interface
- the repository will be used by non-technical or mixed-skill users
- you want a smoother experience for manual testing and demonstrations

### `view_agent/`

`view_agent/` is the command-line version of the workflow.

It is a Python application that receives a view name and a natural-language criterion, runs the interpretation workflow, and prints the structured JSON result in the terminal. It can also save the result to a file.

Use `view_agent/` when:

- you prefer working in the terminal
- you want to automate executions with scripts or pipelines
- you need direct JSON output for integrations or experiments

## When To Use Each One

Choose `application/` if your priority is ease of use.

Choose `view_agent/` if your priority is speed, automation, or CLI-based workflows.

In simple terms:

- `application/` is better for interactive use
- `view_agent/` is better for technical and automated use

## Getting Started

If you want the web interface, start with:

- [application/README.md](application/README.md)

If you want the command-line version, start with:

- [view_agent/README.md](view_agent/README.md)

## Important Note

The two folders serve different usage styles, but they are based on the same core idea: turning a natural-language requirement into a structured output that can be reviewed or reused by other tools.
