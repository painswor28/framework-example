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

> DVC is built to make ML models shareable and reproducible. It is designed to handle large files, data sets, machine learning models, and metrics as well as code.
>
> --- [DVC Website](https://dvc.org/)

### Installation

As we are using PDM for managing python dependencies of the project, we are able to add DVC by running `pdm add dvc`. This will add it to the `pyproject.toml` file and install it into the environment.

### Initialization

To add DVC to the project, we need to do a one time initialization by running `pdm run dvc init`. This will generate a `.dvc` directory which stores it's [internal files](https://dvc.org/doc/user-guide/project-structure/internal-files) as well as a files to DVC what files it should ignore.

### Program Execution

The first place to start using DVC is to wrap the execution of the model with DVC, allowing dvc to track specified dependencies, parameters and outputs. 

At the moment, our primary dependency is the python file itself, and we should also include the pyproject.toml and pdm.lock files as our results might change if we change something about our dependencies.

```bash
pdm run dvc stage add -n tutorial -d quickstart_tutorial.py -d pyproject.toml -d pdm.lock python quickstart_tutorial.py
```

### Reproducing Results

DVC allows us to reproduce the results by running `pdm run dvc repro`. This will execute the code and track the information we have told DVC to track. It stores this information in te `dvc.lock` file. If we run the repro command again, DVC will tell us that nothing changed and so we don't need to run anything.

### Input Dependency Tracking

When we first ran the repro command, pytorch downloaded an input dataset. It is possible that a future version of PyTorch, or the web URL may redirect to a different dataset. With DVC, we can tell it to keep track of our input dataset and it will make sure that it does not change (unless we ask it to). 

By running `pdm run dvc add data`, we can tell DVC to track the data directory. It will hash the files and create a `data.dvc` file that stores metadata about the folder.

Once we have added the data folder to DVC's tracking, we need to update our pipeline stage to add the data directory as a dependency to our command. To do that, we run the following (notice the `-f` flag to force updating the entry in `dvc.yaml` and the `-d data` which adds the data directory as a dependency)

```bash
pdm run dvc stage add -f \
    -n tutorial \
    -d quickstart_tutorial.py \
    -d pyproject.toml \
    -d pdm.lock \
    -d data \
    python quickstart_tutorial.py
```

Now, we can run `pdm run dvc repro` and it will regenerate the lock file which will now also contain the data directory metadata.

### Pipelines

Until now, we have added a single stage to our pipeline. In a real application, we should seperate these stages out into individual functions to allow us to better track their dependencies and only re-execute stages that have an input that has changed. 

To do this, we are going to split out the evaluation stage of `quickstart_tutorial.py` and create `quickstart_tutorial_eval.py`. First, we need to update the first stage to mark `model.pth` as an output.

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

Now, we can run `pdm run dvc repro` and it will run both stages in order and regenerate the lock file. From now on, the evaluate phase will only be executed if the output from the training stage changes.