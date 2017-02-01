@ECHO OFF
REM Builds css files by sassc, generates static html site and uploads it into gh-pages repo branch.
REM
REM Created by Alexander Zolotarev <me@alex.bio> from Minsk, Belarus.

SETLOCAL

REM Publish folder where static html content is generated.
SET out_dir=docs

REM Is git present in PATH?
WHERE /Q git || ECHO ERROR Please install git for Windows or GitHub Desktop. && EXIT /B 1
REM Is php present in PATH?
WHERE /Q php || ECHO ERROR Please install php and/or add it into the PATH. && EXIT /B 1
IF NOT EXIST .git (
  ECHO ERROR: It is not a git repository.
  EXIT /B 1
)
REM Publish folder should be in .gitignore.
git check-ignore -q %out_dir% || ECHO ERROR: Please git rm %out_dir%; git commit -a; and add %out_dir% to .gitignore. && EXIT /B 1
REM Is it a root folder?
IF NOT EXIST deploy.cmd (
  ECHO ERROR: Please launch this script from the site root folder.
  EXIT /B 1
)

REM Is it a git repo?
IF NOT EXIST .git (
  ECHO ERROR: This is not a git repository. It should be a GitHub cloned repo.
  EXIT /B 1
)

REM Repo should be up-to-date.
git remote update || ECHO ERROR with git remote update && EXIT /B 1

REM Setup cloned git repo in the generated folder.
IF NOT EXIST %out_dir%\.git (
  ECHO Initializing %out_dir% folder and binding it to gh-pages branch of the same repository.
  IF EXIST %out_dir% RMDIR /S /Q %out_dir%
  MKDIR %out_dir%
  ROBOCOPY /E /NJH /NJS /NP /NS /NC /NFL /NDL .git %out_dir%\.git
  IF %ERRORLEVEL% GTR 7 (
    ECHO ERROR with robocopy
    EXIT /B 1
  )
)

REM Initialize and switch to gh-pages branch in the docs/.git repo.
PUSHD %out_dir% || ECHO ERROR with PUSHD %out_dir% && EXIT /B 1
git checkout gh-pages > nul 2>&1 || (
  git checkout --orphan gh-pages || ECHO ERROR with git checkout --orphan gh-pages && EXIT /B 1
  git rm -rf . || ECHO ERROR with git rm && EXIT /B 1
)
REM Clean all untracked files.
git clean -f
POPD

REM Build/generate static web site.
REM Build script can delete everything in %out_dir% so %out_dir%\.git folder should be backed up and restored.
REM Move does not work with hidden directories.
ATTRIB -h %out_dir%\.git
MOVE %out_dir%\.git .git.backup || ECHO ERROR while move to .git.backup && EXIT /B 1
CALL %~dp0\build.cmd || ECHO ERROR while calling build.cmd && EXIT /B 1
MOVE .git.backup %out_dir%\.git || ECHO ERROR while move from .git.backup && EXIT /B 1
ATTRIB +h %out_dir%\.git

REM Check if there are any changes to publish.
PUSHD %out_dir% || ECHO ERROR with PUSHD %out_dir% && EXIT /B 1
REM Trick with `find` counts output lines from previous command, like `wc -l` on *nix systems.
FOR /F "tokens=* USEBACKQ" %%F IN (`git status --porcelain ^| FIND /C /V ""`) DO SET changed_files=%%F
IF %changed_files% EQU 0 (
  ECHO There is nothing to publish. Have you made any changes?
  POPD
  EXIT /B 0
)

REM Publish web site to Github Pages.
git add -A || ECHO ERROR with git add -A && EXIT /B 1
git commit -m "Regenerated by deployment script." || ECHO ERROR with git commit -m && EXIT /B 1
git push -u origin gh-pages || ECHO ERROR with git push && EXIT /B 1
POPD
ECHO Successfully published changes to GitHub Pages.
