#!/usr/bin/env python3
"""Explorer..."""

import click
import multiprocessing
import subprocess
import textwrap

from dataclasses import dataclass
from itertools import product
from pathlib import Path
from typing import List


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
    description: str
    tag: str
    lag: int
    stan: str
    r: str


@dataclass
class Run:
    dset: Dataset
    detrend: DetrendMethod
    memvar: MemoryVariable
    covars: Covariates
    model: Model

    @property
    def path(self):
        return Path('output') / self.dset.tag / self.detrend.tag / self.memvar.name / ujoin(self.covars.names) / self.model.tag / f'lag{self.model.lag}'


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

memory_variables = [
    MemoryVariable('tmin.may'),
    MemoryVariable('tmean.aug'),
]

covariates = [
    Covariates(['ppt.aug', 'pdsi.sep']),
]

models = [
    Model('IMP; log(Y)', 'imp_logy', 6, 'ecomem_basis_imp_logy_0dmem.stan', 'fit_ecomem_basis_imp_ndmem.R')
]

runs = [
    Run(dset, detrend, memvar, covars, model) for dset, detrend, memvar, covars, model in product(datasets, detrending_methods, memory_variables, covariates, models)
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


def commit():
    p = subprocess.run(['git', 'rev-parse', 'HEAD'],
                       stdout=subprocess.PIPE, encoding='ascii', check=True)
    return p.stdout.strip()


#
# Overview
#

@cli.command()
def overview():
    """Print overview of runs."""
    print('')
    print('# Datasets')
    print('')

    # XXX type and climate
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

    print(f'| {"tag":10} | {"description":40} | {"lag":3} | {"stan":40} | {"r":40} |')
    print(f'|-{10*"-"}-|-{40*"-"}-|-{3*"-"}-|-{40*"-"}-|-{40*"-"}-|')

    # XXX r
    for model in models:
        print(f'| {model.tag:10} | {model.description:40} | {model.lag:3} | {model.stan:40} | {model.r:40} |')
    print('')

    print('# Runs')
    print('')

    print(f'| {"dataset":10} | {"detrend":24} | {"memvar":12} | {"covars":24} | {"lag":3} | {"model":12} | {"path":80} |')
    print(f'|-{10*"-"}-|-{24*"-"}-|-{12*"-"}-|-{24*"-"}-|-{3*"-"}-|-{12*"-"}-|-{80*"-"}-|')

    for run in runs:
        print(f'| {run.dset.tag:10} | {run.detrend.tag:24} | {run.memvar.name:12} | {cjoin(run.covars.names):24} | {run.model.lag:3} | {run.model.tag:12} | {str(run.path):80} |')


def rscript(run):
    """Generate a R script to perform the run."""

    suffix = commit()[:8]
    return textwrap.dedent(f'''\
      # dataset info
      sites            = c({qcjoin(run.dset.sites)})
      type             = '{run.dset.type}'
      detrend_method   = '{run.detrend.tag}'
      covars           = c({qcjoin(run.covars.names)})
      mem_var          = '{run.memvar.name}'
      lag              = {run.model.lag}

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
@click.option('--allow-dirty', default=False, is_flag=True, help='Allow the repo to be dirty.')
@click.option('--processes', type=int, default=None, help='Number of runs to perform concurrently.')
def execute(allow_dirty, processes):
    """Execute all the runs..."""
    if not allow_dirty and is_dirty():
        print("REPO IS DIRTY!")
        raise SystemExit

    with multiprocessing.Pool(processes) as p:
        p.map(execute1, runs)


#
# Main
#

if __name__ == '__main__':
    cli()
