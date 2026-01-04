# Agent Instructions for Hugo Development

This document provides guidance for AI agents working on this Hugo-based project.

## Running the Hugo Development Server

The standard command to run the development server in the intended Nix environment is:

```bash
nix run . -- server
```

However, the Nix environment is not available in the current sandbox. The following manual steps are required to start the Hugo server:

1.  **Install Hugo:** Ensure Hugo is installed. If not, you can install it using the following commands:
    ```bash
    wget https://github.com/gohugoio/hugo/releases/download/v0.124.0/hugo_extended_0.124.0_Linux-64bit.tar.gz
    tar -xvf hugo_extended_0.124.0_Linux-64bit.tar.gz
    sudo mv hugo /usr/bin/hugo
    ```

2.  **Manually Clone Themes:** The Hugo module system is not reliable in this environment. You must manually clone the required themes into the `themes` directory.
    ```bash
    git clone https://github.com/luizdepra/hugo-coder themes/hugo-coder
    git clone https://github.com/martignoni/hugo-notice themes/hugo-notice
    ```

3.  **Fix Theme Partials:** The `hugo-coder` theme has a non-standard directory structure. Rename the `_partials` directory to `partials` to allow the build to succeed.
    ```bash
    mv themes/hugo-coder/layouts/_partials themes/hugo-coder/layouts/partials
    ```

4.  **Start the Server:** Now you can run the Hugo development server.
    ```bash
    hugo server &
    ```

## Validating UI Changes with Screenshots

All frontend changes must be visually verified before submission. Follow these steps to ensure your changes appear as intended.

1.  **Start the Application:** Follow the instructions in the previous section to start the Hugo development server.

2.  **Create a Verification Script:**
    -   Create a temporary directory for your verification files: `mkdir -p /home/jules/verification`.
    -   Write a headless Playwright script that navigates to the relevant page and demonstrates your changes.
    -   The script **must** take a screenshot of the final state.
    -   Save the script to `/home/jules/verification/verify_changes.py`.

3.  **Generate the Screenshot:**
    -   Run your script to generate the screenshot: `python /home/jules/verification/verify_changes.py`.
    -   Ensure the script saves the screenshot to a known path, such as `/home/jules/verification/verification.png`.

4.  **Visually Inspect the Screenshot:**
    -   Use the `read_image_file` tool to load and review the screenshot you just created.
    -   Example: `read_image_file(filepath='/home/jules/verification/verification.png')`
    -   Carefully check if the changes are correct. If not, modify your implementation and repeat from step 3.

5.  **Confirm Verification:**
    -   Once you are satisfied with the screenshot, call the `frontend_verification_complete` tool to mark the step as done.
    -   Example: `frontend_verification_complete(screenshot_path='/home/jules/verification/verification.png')`
