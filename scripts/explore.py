#!/usr/bin/env python3
"""Explorer..."""

import click
import multiprocessing
import subprocess
import textwrap

from dataclasses import dataclass
from itertools import product
from pathlib import Path
from shutil import copyfile
from typing import List

top = Path(__file__).resolve().parent.parent


@click.group()
def cli():
    pass


#
# Definitions
#

@dataclass
class Dataset:
    tag: str
    description: str
    type: str
    sites: List[str]


@dataclass
class DetrendMethod:
    tag: str
    description: str


@dataclass
class MemoryVariable:
    name: str


@dataclass
class Covariates:
    names: List[str]


@dataclass
class Model:
    tag: str
    description: str
    lag: int
    sigma: float
    stan: str
    r: str


@dataclass
class Run:
    tag: str
    dset: Dataset
    detrend: DetrendMethod
    memvar: MemoryVariable
    covars: Covariates
    model: Model

    @property
    def path(self):
        return Path('output') / self.dset.tag / self.detrend.tag / self.memvar.name / ujoin(self.covars.names) / self.model.tag

    def __post_init__(self):
        covars = set(self.covars.names)
        if self.memvar.name in covars:
            covars.remove(self.memvar.name)
            self.covars = Covariates(list(covars))

datasets = [
    Dataset('three-bi', 'Three sites (BTP, CBS, TOW); BI', 'bi', ["BTP", "CBS", "TOW"]),
    Dataset('three-rw', 'Three sites (BTP, CBW, TOW); RW', 'rw', ["BTP", "CBS", "TOW"]),
]

detrending_methods = [
    DetrendMethod('mean', 'X'),
    DetrendMethod('ModNegExp', 'X'),
    DetrendMethod('Spline30', 'X'),
    DetrendMethod('Spline50', 'X'),
    DetrendMethod('Spline80', 'X'),
    DetrendMethod('Friedman', 'X'),
    DetrendMethod('ModHugershoff', 'X'),
]

modern_memory_variables = [
    MemoryVariable('tmin.may'),
    MemoryVariable('tmean.aug'),
]

paleo_memory_variables = [
    MemoryVariable('stream.yel'),
    MemoryVariable('swe.yel'),
]

modern_covariates = [
    Covariates(['ppt.aug', 'pdsi.sep']),
]

paleo_covariates = [
    Covariates(['stream.yel', 'swe.yel', 'tmax.lsum']),
]

models = [
    Model('imp_logy-lag6-sigma010', 'IMP; log(Y)', 6, 0.10, 'ecomem_basis_imp_logy_0dmem.stan', 'fit_ecomem_basis_imp_ndmem.R'),
    Model('imp_logy-lag6-sigma022', 'IMP; log(Y)', 6, 0.22, 'ecomem_basis_imp_logy_0dmem.stan', 'fit_ecomem_basis_imp_ndmem.R'),
    Model('imp_logy-lag6-sigma032', 'IMP; log(Y)', 6, 0.32, 'ecomem_basis_imp_logy_0dmem.stan', 'fit_ecomem_basis_imp_ndmem.R'),
    Model('imp_logy-lag6-sigma045', 'IMP; log(Y)', 6, 0.45, 'ecomem_basis_imp_logy_0dmem.stan', 'fit_ecomem_basis_imp_ndmem.R'),
    Model('imp_logy-lag6-sigma055', 'IMP; log(Y)', 6, 0.55, 'ecomem_basis_imp_logy_0dmem.stan', 'fit_ecomem_basis_imp_ndmem.R'),
]

runs = [
    Run('modern', dset, detrend, memvar, covars, model)
      for dset, detrend, memvar, covars, model
      in product(datasets, detrending_methods, modern_memory_variables, modern_covariates, models)
] + [
    Run('paleo', dset, detrend, memvar, covars, model)
      for dset, detrend, memvar, covars, model
      in product(datasets, detrending_methods, paleo_memory_variables, paleo_covariates, models)
]

plot = 'plot_ecomem_basis_imp.R'


#
# Helpers
#

def cjoin(xs):
    return ','.join([str(x) for x in xs])


def qcjoin(xs):
    return ','.join(['"' + str(x) + '"' for x in xs])


def ujoin(xs):
    return '_'.join([str(x) for x in xs])


def is_dirty():
    p = subprocess.run(['git', 'diff-index', '--quiet', 'HEAD'], check=False)
    return p.returncode != 0


def git_commit():
    p = subprocess.run(['git', 'rev-parse', 'HEAD'],
                       stdout=subprocess.PIPE, encoding='ascii', check=True)
    return p.stdout.strip()


def mgetattr(obj, attrs):
    o = obj
    for attr in attrs:
        o = getattr(o, attr)
    return o

#
# Overview
#

@cli.command()
def overview():
    """Print overview of runs."""
    print('')
    print('# Datasets')
    print('')

    print(f'| {"tag":10} | {"description":40} | {"files":80} |')
    print(f'|-{10*"-"}-|-{40*"-"}-|-{80*"-"}-|')

    for dset in datasets:
        print(f'| {dset.tag:10} | {dset.description:40} | {cjoin(dset.sites):80} |')

    print('')
    print('# Detrending methods')
    print('')

    print(f'| {"tag":24} | {"description":40} | ')
    print(f'|-{24*"-"}-|-{40*"-"}-|')

    for detrend in detrending_methods:
        print(f'| {detrend.tag:24} | {detrend.description:40} |')

    print('')
    print('# Models')
    print('')

    print(f'| {"tag":40} | {"description":30} | {"lag":3} | {"sigma":10} | {"stan":40} | {"r":40} |')
    print(f'|-{40*"-"}-|-{30*"-"}-|-{3*"-"}-|-{10*"-"}-|-{40*"-"}-|-{40*"-"}-|')

    for model in models:
        print(f'| {model.tag:40} | {model.description:30} | {model.lag:3} | {model.sigma:10.4f} | {model.stan:40} | {model.r:40} |')
    print('')

    print('# Runs')
    print('')

    print(f'| {"tag":10} | {"dataset":10} | {"detrend":24} | {"memvar":12} | {"covars":24} | {"model":12} |')
    print(f'|-{10*"-"}-|-{10*"-"}-|-{24*"-"}-|-{12*"-"}-|-{24*"-"}-|-{12*"-"}-|')

    for run in runs:
        print(f'| {run.tag:10} | {run.dset.tag:10} | {run.detrend.tag:24} | {run.memvar.name:12} | {cjoin(run.covars.names):24} | {run.model.tag:12} |')


def rscript(run):
    """Generate a R script to perform the run."""

    suffix = git_commit()[:8]
    return textwrap.dedent(f'''\
      # dataset info
      sites            = c({qcjoin(run.dset.sites)})
      type             = '{run.dset.type}'
      detrend_method   = '{run.detrend.tag}'
      covars           = c({qcjoin(run.covars.names)})
      mem_var          = '{run.memvar.name}'
      lag              = {run.model.lag}
      sigma            = {run.model.sigma}

      # stan
      N_iter           = 1000
      model_name       = 'scripts/{run.model.stan}'
      include_outbreak = 0
      include_fire     = 0
      include_inits    = 0

      # output
      suffix           = '{suffix}'
      path_output      = '{run.path}'
      path_figures     = '{run.path}'

      # go!
      source("scripts/{run.model.r}")
      source("scripts/{plot}")
      ''')


def execute1(run):
    """Execuate a single run."""
    run.path.mkdir(exist_ok=True, parents=True)

    rfile = run.path / 'run.R'
    rfile.write_text(rscript(run))

    log = run.path / 'run.log'
    with log.open('w') as f:
        print(f'running: {rfile}')
        p = subprocess.run(['Rscript', str(rfile)], stdout=f, stderr=f, check=False)
        if p.returncode != 0:
            print(f'WARNING: {rfile} failed; see {log}')


@cli.command()
@click.option('--filter', default=None)
@click.option('--allow-dirty', default=False, is_flag=True, help='Allow the repo to be dirty.')
@click.option('--processes', type=int, default=None, help='Number of runs to perform concurrently.')
@click.option('--dry-run', default=False, is_flag=True, help='Dry run.')
def execute(filter, allow_dirty, processes, dry_run):
    """Execute all the runs..."""
    if not allow_dirty and is_dirty():
        print("REPO IS DIRTY!")
        return

    filtered_runs = list(runs)
    for f in filter.split('/'):
        attrs, value = f.split(':')
        attrs = attrs.split('.')
        filtered_runs = [run for run in filtered_runs if mgetattr(run, attrs) == value]

    if dry_run:
        for run in filtered_runs:
            print(run)
    else:
        with multiprocessing.Pool(processes) as p:
            p.map(execute1, filtered_runs)


@cli.command()
@click.option('--commit', default=None)
def consolidate(commit):
    """Consolidate figures..."""

    dest = Path(top / 'output' / 'consolidated')
    dest.mkdir(exist_ok=True)

    if commit is None:
        commit = git_commit()[:8]

    for run in runs:
        src = run.path / commit / f'cmem_antecedent-weight-_{commit}.png'
        dst = dest / f'cmem_antecedent-weight-{run.dset.tag}-{run.detrend.tag}-{run.memvar.name}-{ujoin(run.covars.names)}-{run.model.tag}-{commit}.png'
        if src.exists():
            copyfile(src, dst)


#
# Main
#

if __name__ == '__main__':
    cli()
