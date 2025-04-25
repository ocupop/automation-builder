#!/usr/bin/env python3
"""
start_services.py

This script extends the functionality from lib/local-ai-packaged/start_services.py.
It starts the Supabase stack first, waits for it to initialize, then starts
the local AI stack, and finally starts base services.
"""

import os
import subprocess
import shutil
import time
import argparse
import importlib.util
import sys

# Dynamically import the original start_services.py from lib/local-ai-packaged
source_script_path = os.path.join(
    "lib", "local-ai-packaged", "start_services.py")
spec = importlib.util.spec_from_file_location(
    "source_services", source_script_path)
source_services = importlib.util.module_from_spec(spec)
sys.modules["source_services"] = source_services
spec.loader.exec_module(source_services)

# Define our own functions where we need to customize behavior


def run_command(cmd, cwd=None):
    """Run a shell command and print it."""
    print("Running:", " ".join(cmd))
    subprocess.run(cmd, cwd=cwd, check=True)


def prepare_local_ai_env():
    """Copy .env to .env in lib/local-ai-packaged."""
    env_path = os.path.join("lib", "local-ai-packaged", ".env")
    env_example_path = os.path.join(".env")
    print("Copying .env in root to .env in lib/local-ai-packaged...")
    shutil.copyfile(env_example_path, env_path)


def stop_existing_containers():
    """Stop and remove existing containers for our unified project."""
    print("Stopping and removing existing containers...")
    run_command([
        "docker", "compose",
        "-p", "localai",
        "-f", "docker-compose.yml",
        "-f", os.path.join("lib", "local-ai-packaged", "docker-compose.yml"),
        "-f", "supabase/docker/docker-compose.yml",
        "down"
    ])


def start_local_ai(profile=None):
    """Start the local AI services using the compose file in lib/local-ai-packaged."""
    print("Starting local AI services...")
    local_ai_compose = os.path.join(
        "lib", "local-ai-packaged", "docker-compose.yml")
    if not os.path.exists(local_ai_compose):
        raise FileNotFoundError(
            f"Local AI docker-compose file not found at: {local_ai_compose}")

    # Prepare the environment file
    prepare_local_ai_env()

    # Create symlink for SearXNG if needed
    source_searxng_dir = os.path.join("lib", "local-ai-packaged", "searxng")
    target_searxng_dir = os.path.join("searxng")
    if not os.path.exists(target_searxng_dir) and os.path.exists(source_searxng_dir):
        print(
            f"Creating symlink from {source_searxng_dir} to {target_searxng_dir}")
        if sys.platform == "win32":
            # On Windows, use a directory junction
            os.system(
                f'mklink /J "{target_searxng_dir}" "{source_searxng_dir}"')
        else:
            # On Unix-like systems, use a symlink
            os.symlink(source_searxng_dir, target_searxng_dir,
                       target_is_directory=True)

    cmd = ["docker", "compose", "-p", "localai"]
    if profile and profile != "none":
        cmd.extend(["--profile", profile])
    cmd.extend(["-f", local_ai_compose, "up", "-d"])
    run_command(cmd)


def start_base_services(profile=None):
    """Start the base services using the root docker-compose.yml file."""
    print("Starting base services...")
    cmd = ["docker", "compose", "-p", "localai"]
    if profile and profile != "none":
        cmd.extend(["--profile", profile])
    cmd.extend(["-f", "docker-compose.yml", "up", "-d"])
    run_command(cmd)


def main():
    parser = argparse.ArgumentParser(
        description='Start the local AI and Supabase services.')
    parser.add_argument('--profile', choices=['cpu', 'gpu-nvidia', 'gpu-amd', 'none'], default='cpu',
                        help='Profile to use for Docker Compose (default: cpu)')
    args = parser.parse_args()

    # Use original functions where appropriate
    source_services.clone_supabase_repo()
    prepare_supabase_env = source_services.prepare_supabase_env
    prepare_supabase_env()
    stop_existing_containers()  # Use our custom implementation

    # Start Supabase first
    start_supabase = source_services.start_supabase
    start_supabase()

    # Give Supabase some time to initialize
    print("Waiting for Supabase to initialize...")
    time.sleep(10)

    # Then start the local AI services
    start_local_ai(args.profile)  # Use our custom implementation

    print("Waiting for local AI to initialize...")
    time.sleep(10)

    # Start base services
    start_base_services(args.profile)  # Use our custom implementation


if __name__ == "__main__":
    main()
