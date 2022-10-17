[![pdm-managed](https://img.shields.io/badge/pdm-managed-blueviolet)](https://pdm.fming.dev)

# Framework Example

An example taking the PyTorch [beginner quickstart project](https://pytorch.org/tutorials/beginner/basics/quickstart_tutorial.html) and wrapping it with the best practices of the framework group.

## PDM

> PDM, as described, is a modern Python package and dependency manager supporting the latest PEP standards. But it is more than a package manager. It boosts your development workflow in various aspects. The most significant benefit is it installs and manages packages in a similar way to npm that doesn't need to create a virtualenv at all!
>
> --- [PDM Documentation](https://pdm.fming.dev/latest/#introduction)

As part of the framework best practices we use PDM to manage dependencies of our python software. 

### Installation

PDM should be installed as described in the [Installation instructions](https://pdm.fming.dev/latest/#recommended-installation-method).

### Configuration

PDM provides two ways of storing dependencies, via [virtual environments](https://packaging.python.org/en/latest/guides/installing-using-pip-and-virtual-environments/#creating-a-virtual-environment) and via [PEP 583](https://peps.python.org/pep-0582/). The PEP 582 method is suggested as it allows self contained project directories. To enable PEP 582 mode, the following command should be executed in the project directory and will create a file called `.pdm.toml`.
```bash
pdm config --local python.use_venv False
```

### Initialization

Once PDM is installed and configured, the project should be initialized by running the following command. This will ask a series of questions, where the defaults are usually safe, and produce a file called `pyproject.toml`.
```bash
pdm init
```

### Dependency Management

Once we have initialized the project, we need to add the dependencies to the project so we can use them and keep track of the versions we know the project works with. The easiest way of starting this is to find all of the `import` or `from` statements in the python files and include the modules they reference. In this project, we need to add pytorch (`torch` here) and torchvision.

```bash
pdm add torch torchvision
```

### Execution

When we have defined our dependencies, we can then run the software. There are two paths to this, if we [globally enable PEP 582](https://pdm.fming.dev/latest/usage/pep582/#enable-pep-582-globally) then we are able to run the code with as a normal python script e.g. `python quickstart_tutorial.py`. However, we can also run in an isolated environment by using `pdm run python quickstart_tutorial.py`.

## Data Version Control (DVC)

Add DVC to our project and initialize it:

```bash
pdm add dvc
```

and then

```bash
pdm run dvc init
```

DVC will create the `.dvc` directory to store its [internal files](https://dvc.org/doc/user-guide/project-structure/internal-files).

We will set up a DVC pipeline to track specified dependencies, parameters and outputs.

Our primary dependency is the python file itself, and we should also include the pyproject.toml and pdm.lock files as our results might change if we change something about our dependencies.

```bash
pdm run dvc stage add \
    -n tutorial \
    -d quickstart_tutorial.py \
    -d pyproject.toml \
    -d pdm.lock \
    python quickstart_tutorial.py
```

This command adds a staged named "tutorial" that depends on the three files, and executes the command `python quickstart_tutorial.py`.

Run the pipeline now:

```bash
pdm run dvc repro
```

This executes the code and track the information we have told DVC to track.
It stores this information in the `dvc.lock` file.
If we run the repro command again, DVC will tell us that nothing changed and doesn't run anything.

### Input Dependency Tracking

When we first ran the repro command, pytorch downloaded an input dataset.
It is possible that a future version of PyTorch, or the web URL may redirect to a different dataset.
With DVC, we can tell it to keep track of our input dataset and it will make sure that it does not change (unless we ask it to).
Let's tell DVC to track the data directory:

```bash
pdm run dvc add data
```

This creates the `data.dvc` file to store metadata about the folder.
Now update the pipeline stage to depend on the data directory:

```bash
pdm run dvc stage add -f \
    -n tutorial \
    -d quickstart_tutorial.py \
    -d pyproject.toml \
    -d pdm.lock \
    -d data \
    python quickstart_tutorial.py
```

(note the `-f` flag to force updating the entry in `dvc.yaml` and the `-d data` which adds the data directory as a dependency)
Now, we can run `pdm run dvc repro` and it will regenerate the lock file which will now also contain the data directory metadata.

### Pipelines

Our pipeline has a single stage, but a real application would have many more to better track dependencies and only re-execute stages that have an input that has changed.

Let's split out the evaluation stage of `quickstart_tutorial.py` and create `quickstart_tutorial_eval.py`.
First, we need to update the first stage to mark `model.pth` as an output.
(note the `-o` option)

```bash
pdm run dvc stage add -f \
    -n tutorial \
    -d quickstart_tutorial.py \
    -d pyproject.toml \
    -d pdm.lock \
    -d data \
    -o model.pth \
    python quickstart_tutorial.py
```

Then, we add a new stage that uses that output as a dependency.

```bash
pdm run dvc stage add -f \
    -n evaluate \
    -d quickstart_tutorial_eval.py \
    -d pyproject.toml \
    -d pdm.lock \
    -d data \
    -d model.pth \
    python quickstart_tutorial_eval.py
```

Now, we can run `pdm run dvc repro` and it will run both stages in order and regenerate the lock file.
From now on, the evaluate phase will only be executed if the output from the training stage changes.

### Parameters
```bash
pdm run dvc stage add -f \
    -n tutorial \
    -d quickstart_tutorial.py \
    -d pyproject.toml \
    -d pdm.lock \
    -d data \
    -o model.pth \
    -p batch_size \
    -p lr \
    -p epochs \
    python quickstart_tutorial.py
```

### Metrics and Plots
```bash
pdm run dvc stage add -f \
    -n tutorial \
    -d quickstart_tutorial.py \
    -d pyproject.toml \
    -d pdm.lock \
    -d data \
    -o model.pth \
    -p batch_size \
    -p lr \
    -p epochs \
    -M training.json \
    --plots-no-cache training/scalars \
    python quickstart_tutorial.py
```

### Remotes
Until now, all of our project data is kept within this directory. To make collaboration easier, DVC provides the ability to specify remotes. These are places to store any data cached by DVC such as input files or output files. 

To start with a local example that would work on a shared machine. Assuming `/mnt/data` is a valid folder that is accessable by multiple people who wish to collaborate, we can add that directory as a cache within DVC by running `pdm run dvc remote add -d shared_folder /mnt/data`. We can compare our cached data to that of the cache by running `pdm run dvc status -r shared_folder` and it will show we have a number of new files that are not in the shared cache. Now, we can push our data to that shared folder with `pdm run dvc push`. Now, when a new person on the machine that has access to `/mnt/data`, clones the repository they can run `pdm run dvc pull -r shared_folder && pdm run dvc checkout` and they will get a copy of the cached data.

We may want this project to be more globally accessible. To do so, we can use one of DVC's [online remotes](https://dvc.org/doc/command-reference/remote#description). As an example, we can add a google drive folder as a remote for the project with `pdm run dvc remote add drive 'gdrive://1UhgZ96wcORoFXUMI0YDUZ4dPF7QJwOUz'` where `1UhgZ96wcORoFXUMI0YDUZ4dPF7QJwOUz` is the folder ID. We can then do the same as with a local remote and push our data with `pdm run dvc push -r drive`.