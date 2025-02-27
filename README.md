# pm2-installer

`pm2-installer` is designed to automate installation of pm2 as a service on Windows.

### Windows Support

Unfortunately, PM2 has no built-in startup support for Windows. PM2's [documentation](https://pm2.keymetrics.io/docs/usage/startup/#windows-consideration) recommends using either `pm2-windows-service` or `pm2-windows-startup`. However, both of these projects have some real drawbacks.

`pm2-windows-startup` adds an entry to the registry to start pm2 after user login. Because it does not create a service, PM2 will not be running until a user has logged into the user interface, and will halt when they log out. It has not been updated since 2015.

`pm2-windows-service` uses `node-windows` to create a service that runs pm2. This is a much better approach, but it hasn't been maintained since 2018, has outdated dependencies that cause crashes on setup, and currently fails to run properly on Node 14. It also runs the service as the the `Local System` user instead of `Local Service`.

`jessety/pm2-installer` also used `node-windows`, but the most recent version (July 2023) includes a version of [WinSW](https://github.com/winsw/winsw) that is compiled with .NET v2, which is not supported on Windows Server 2019. It also uses a command-line permissions elevator that is [blocked by Carbon Black](https://github.com/coreybutler/node-windows/issues/320#issuecomment-1250006737).

This project drops `node-windows` in favor of a .NET v4.6.1 executable from [WinSW v2.12](https://github.com/winsw/winsw/releases/tag/v2.12.0). The supporting configuration changes from `jessety/pm2-installer` are maintained:

- Configure `npm` to keep its global files in `C:\ProgramData\npm`, instead of keeping them in the current user's `%APPDATA%`
- Install `pm2` globally, using an offline cache if necessary
- Create the `C:\ProgramData\pm2` directory and set the `PM2_HOME` environmental variable at the machine level
- Set permissions both the new `npm` and `pm2` folders so that the Local Service user may access them

But then, a new script to create the XML configuration for the WinSW executable is called with mostly hardcoded values. The remaining PowerShell scripts have been adjusted to support this more direct approach, and some verification of the service has been dropped.

After installation, `pm2` will be running in the background under the `Local Service` user. It will persist across reboots and continue running regardless of which user is logged in. To add your app, run `pm2 start app.js` from an admin command line interface. Make sure to run `pm2 save` to serialize the process list.

## Windows Install

There are a couple challenges when installing on a fresh Windows machine. The `npm` global directory is not accessible to other users by default, which means the `Local Service` user will not be able to locate the `pm2` executable. Additionally, if the machine's PowerShell execution policy is `Undefined` or `Restricted`, invoking `pm2` in PowerShell will fail- even though the setup script unblocks `pm2.ps1`.

`pm2-installer` includes two additional scripts to automatically fix the above issues. Invoking `npm run configure` will create the `C:\ProgramData\npm\`, and set `npm` to use `prefix` and `cache` locations in that directory. Running `npm run configure-policy` checks the machine's PowerShell execution policy and if it is either `undefined` or `Restricted`, updates it to `RemoteSigned`.

After you have cloned the repository onto the target machine, 
open an **elevated** terminal (e.g. right click and select "Run as Admin"). Run the following commands first:

```pwsh
npm run configure
npm run configure-policy
```

Then to configure and install the service, run:

```bash
npm run setup
```

#### Additional context for Windows installations

- The `pm2` service runs as the `Local Service` user. To interact with `pm2`, you need to use an elevated terminal (e.g. right click and select "Run as Admin") before running any commands that interface with the service, e.g. `pm2 list`.
- If you update node and npm, make sure to either manually re-configure your npm & node installations or run `npm run configure` again.
- This project does not currently support nvm for windows. It requires a standard node installation.

## Removal

To remove the pm2 service, run:

```bash
npm run remove
```

This will remove the service and completely uninstall pm2.

If you used the `configure` script on Windows to configure `npm`, you can revert those settings by running:

```bash
npm run deconfigure
```
