# Bash: Move Git Files with History

Simple bash script to move files between git repos while maintaining history.

This script was created from a lot of great content from other people, most notably:

- [Ayushya Jaiswal: Move files from one repository to another, preserving git history](https://github.com/kevmurray/bash-move-git-files-with-history)
- [wevtimoteo/example.md](https://gist.github.com/wevtimoteo/a6f4b0837cdc3749dd6b)
- [trongthanh/gist:2779392](https://gist.github.com/trongthanh/2779392)

My goal here was to create a script that could do basic file copies between git repos while keeping it simple enough to also copy and paste commands from it if I didn't want to do exactly what was scripted.

## Use Cases

There are two main use cases:

### Move an entire repo into another repo

I need to assemble a monorepo from several dozen separate repos. 
So the first mode takes 3 parameters: a source repository, a target repository and a directory in the target repository. 
It then replicates the entire source repository under the directory in the target repository:

```
move-git-files-between-repos.sh \
    --source-repo=kevmurray/cheeta \
    --target-repo=kevmurray/animals \
    --target-dir=mammals/cats/cheeta
```

This command would take all the files from the https://github.com/kevmurray/cheeta repository (master branch) and move them into https://github.com/kevmurray/animals/mammals/cats/cheeta directory (master branch). 

Before this is run, you might have

```
github.com/kevmurray/cheeta                github.com/kevmurray/animals
├─ .gitignore                              ├─ .gitignore
├─ package.json                            ├─ insects
├─ app.js                                  │  ╰─ ... more files
├─ model                                   ╰─ mammals
│  ├─ spots.js                                ├─ dogs
│  ├─ legs.js                                 │  ╰─ ... more files
│  ╰─ wiskers.js                              ╰─ cats
╰─ control                                       ╰─ lion
  ├─ running.js                                     ╰─ ... more files
  ╰─ grooming.js
```

and after running, you would have

```
github.com/kevmurray/cheeta                github.com/kevmurray/animals
├─ .gitignore                              ├─ .gitignore
├─ package.json                            ├─ insects
├─ app.js                                  │  ╰─ ... more files
├─ model                                   ╰─ mammals
│  ├─ spots.js                                ├─ dogs
│  ├─ legs.js                                 │  ╰─ ... more files
│  ╰─ wiskers.js                              ╰─ cats
╰─ control                                       ├─ cheeta
  ├─ running.js                                  │  ├─ .gitignore
  ╰─ grooming.js                                 │  ├─ package.json
                                                 │  ├─ app.js
                                                 │  ├─ model
                                                 │  │  ├─ spots.js
                                                 │  │  ├─ legs.js
                                                 │  │  ╰─ wiskers.js
                                                 │  ╰─ control
                                                 │    ├─ running.js
                                                 │    ╰─ grooming.js
                                                 ╰─ lion
                                                    ╰─ ... more files
```

Note that, in spite of the name "move" the files in the source repository are not removed or changed, so this is actually a copy.

### Move a directory from one repo into another repo

I need to move a subset of files into another repo. Like moving reusable code out of one repo into a library.
This command takes 4 parameters and moves the contents (not the directory, but the contentst of the directory) to another repo

```
move-git-files-between-repos.sh \
    --source-repo=kevmurray/cheeta \
    --source-dir=model \
    --target-repo=kevmurray/animals \
    --target-dir=mammals/cats/shared
```

This command would take all the files from the https://github.com/kevmurray/cheeta/model directory (master branch) and move them into https://github.com/kevmurray/animals/mammals/cats/shared directory (master branch).

Before this is run, you might have

```
github.com/kevmurray/cheeta                github.com/kevmurray/animals
├─ .gitignore                              ├─ .gitignore
├─ package.json                            ├─ insects
├─ app.js                                  │  ╰─ ... more files
├─ model                                   ╰─ mammals
│  ├─ spots.js                                ├─ dogs
│  ├─ legs.js                                 │  ╰─ ... more files
│  ╰─ wiskers.js                              ╰─ cats
╰─ control                                       ╰─ lion
  ├─ running.js                                     ╰─ ... more files
  ╰─ grooming.js
```

and after running, you would have

```
github.com/kevmurray/cheeta                github.com/kevmurray/animals
├─ .gitignore                              ├─ .gitignore
├─ package.json                            ├─ insects
├─ app.js                                  │  ╰─ ... more files
├─ model                                   ╰─ mammals
│  ├─ spots.js                                ├─ dogs
│  ├─ legs.js                                 │  ╰─ ... more files
│  ╰─ wiskers.js                              ├─ cats
╰─ control                                    │  ╰─ lion
  ├─ running.js                               │     ╰─ ... more files
  ╰─ grooming.js                              ╰─ shared
                                                 ├─ spots.js
                                                 ├─ legs.js
                                                 ╰─ wiskers.js
```

## Operation

You can read more details in the references mentioned above, but in a nutshell this is what happens:
1. The source repository is cloned into the current directory.
2. The origin of the source repository is deleted (this prevents any changes from being pushed back upstream).
3. All files that you don't want to move are deleted from the source repository.
4. The remaining files (that you do want to move) are moved to the target directory, but in the source repository.
5. The target repository is cloned into the current directory.
6. The target repository has a temporary upstream origin created that points to the source repository on your machine (created in step 1).
7. The files are pulled from the source repository using the temporary origin. This is where the magic happens and those files along with their history are imported into this repository.
8. The temporary upstream origin to the source repository on your machine is deleted.
9. The local source repository is deleted (since it's been irreparably mangled by steps 3 and 4).

**Things to think about:**


The script will clone both the source and target repositories into the current directory, so you should probably run it in an empty directory, 
or at least a directory that doesn't already have those repositories in it.

When done, the target repository will be left in the current directory with local changes to it. 
You must push those changes to the target origin manually. Instructions will be printed by the script.

Since the target repository hasn't been pushed, you should review it first to make sure it looks like what you want. 
If it doesn't, simply `rm -rf` it and run the script again with different parameters until you achieve the layout you want.

As previously alluded to, most of the references on the web just describe how to do this and provide a series of individual commands
to copy and paste. I created this script because I needed to move dozens of micro-services into a monorepo, so I wanted a repeatable 
process. That doesn't mean you cannot either customize the script, or just use it as a reference and copy and paste from it into a Terminal.
When I want to do this, I copy the first 12 or so lines that define the variables (and fill out the values I would normally specify
as parameters to the script), then jump down to around line 30 (after the parameter procesing, 
before `localSourceDir` and `localTargetDir` are assigned) and start copying 
line-by-line from there, customizing commands as necessary. 

## Usage

There are a few other parameters that you can use to tweak behavior. 
The following shows all the parameters with default values where there is one, or ??? if you _must_ provide a value.

**--host=https://github.com**  
Sets the git host that the source and target repos are in. There is no way to use a different host for source and target. 
You should be able to copy/paste commands from the script to customize this, though.

**--branch=master**  
Set the branch for both the source and target repositories. I use `master` for everything, but if 
you use `default` or `main` or `develop`, you can switch the default branch name with this.

**--source-repo=???**  
**--from-repo=???**    
You must provide this parameter to be the name of the repo to get the files from. 
This should be the part of the repo after the host name, but before any directories. 
In github it is the user name, slash, repository name. Like `kevmurray/bash-move-git-files-with-history`.

**--source-dir=???**  
**--from-dir=???**  
**--whole-repo**  
This defines the directory containing the files to move to the target repo.
Note that the files moved will be the files in this directory (including sub-directories) but will not include this directory.
You can do all the files in the repo by using `--whole-repo` (or `--source-dir=`, with no name).

**--source-branch=master**  
**--from-branch=master**  
Sets the name of the branch to get the files from. Defaults to the `--branch` value, which defaults to `master`.

**--target-repo=???**  
**--to-repo=???**    
You must provide this parameter to be the path to the repo to put the files into. 
This should be the part of the repo after the host name, but before any directories. 
In github it is the user name, slash, repository name. Like `kevmurray/bash-move-git-files-with-history`.

**--target-dir=???**  
**--to-dir=???**  
This defines the name of the directory that should contain the files after they are moved.
This directory will be created in the target repository if it doesn't already exist.

**--target-branch=master**  
**--to-branch=master**  
Sets the name of the branch to move the files into. 
Defaults to the `--branch` value, which defaults to `master`.  
This branch will be created if it doesn't already exist. So if you typically use branch-based development practices (like Pull Requests), 
set this to the branch name you want to use for the feature. For example, in my workflow I would use something like: 
```
move-git-files-between-repos.sh \
    --source-repo=kevmurray/cheeta \
    --target-repo=kevmurray/animals \
    --target-dir=mammals/cats/cheeta \
    --target-branch=feature/ISSUE-123_migrate-cheeta-to-monorepo
```
When done, the target repo will have this as the current branch and you can push it when you are ready.

## Issues

**Copying files**  
There is currently no way (in this script) to copy just one file, it only works on directories. 
Although that should be possible, I have not needed to do that and haven't put any time into figuring it out.

**Merging directories**  
I never tried to copy files into directories that already exist with their own files (i.e. merging directories).
I don't see any reason it wouldn't work, but test first.

**Name conflicts**  
If you try to move files and a file with that name already exists in the target directory, you will get a merge conflict error. 
If this is what you want, then resolve the conflicts like normal, otherwise delete the target repository and try again with 
different parameters.
