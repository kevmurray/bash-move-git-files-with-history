# Bash: Move Git Files with History

Simple bash script to move files between git repos while maintaining history.

This script was created from a lot of great content from other people, most notably:

- [Ayushya Jaiswal: Move files from one repository to another, preserving git history](https://github.com/kevmurray/bash-move-git-files-with-history)
- [wevtimoteo/example.md](https://gist.github.com/wevtimoteo/a6f4b0837cdc3749dd6b)
- [trongthanh/gist:2779392](https://gist.github.com/trongthanh/2779392)

My goal here was to create a script that could do basic file copies between git repos while keeping it simple enough to also copy and paste commands from it if I didn't want to do exactly what was scripted.

## Usage

There are two main use cases:

### Move an entire repo into another repo
I needed to assemble a monorepo from several dozen separate repos. 
So the first mode takes 3 parameters: a source repository, a target repository and a directory in the target repository. 
It then replicates the entire source repository under the directory in the target repository:

```
move-git-files-between-repos.sh --source-repo=kevmurray/cheeta --target-repo=kevmurray/animals --target-dir=mammals/cats/cheeta
```

This command would take all the files from the https://github.com/kevmurray/cheeta repository (master branch) and move them into https://github.com/kevmurray/animals/mammals/cats/cheeta directory. 

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

Note that, in spite of the name "move" the files in the source repository are not actually damaged, so this is really a copy