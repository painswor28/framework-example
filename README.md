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