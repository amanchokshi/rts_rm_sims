"""
Create RTS style sourclists for calibration & simulations
of polarised sources with given rotation measure
"""

import sys
sys.path.append("../../scripts")
from rm_synth import get_IQUV_complex

import yaml
import numpy as np
from pathlib import Path
from astropy import units as u
from astropy.coordinates import SkyCoord
from matplotlib import pyplot as plt

if __name__ == "__main__":
  
    import argparse

    parser = argparse.ArgumentParser(
            description='Create RTS Style RM sourcelists for Calibration and Simulations'
    )

    parser.add_argument(
        "--yaml_cfg",
        metavar="\b",
        type=str,
        required=True,
        help="Path to srclist yaml config file"
    )

    parser.add_argument(
        "--out_dir",
        metavar="\b",
        type=str,
        default='.',
        help="Path to output directory",
    )

    args = parser.parse_args()

    yaml_cfg = Path(args.yaml_cfg)

    # Make output dir if it doesn't exist
    Path(args.out_dir).mkdir(parents=True, exist_ok=True)

    with open(yaml_cfg, 'r') as stream:
        # config = yaml.load(stream, Loader=yaml.CLoader)
        config = yaml.safe_load(stream)
        
    freqs = np.arange(
            config['sim_freqs']['low_freq'], 
            config['sim_freqs']['high_freq'] + config['sim_freqs']['bw'], 
            config['sim_freqs']['bw']
            )

    # Write calibration srclist
    cal_srclist_name = f"{Path(args.out_dir)}/{config['obsid']}_{yaml_cfg.stem}_cal.txt"
    with open(cal_srclist_name, "w") as f:
        for s, params in config['sources'].items():
          
            if params['type'] == 'calibrator':
                source_coords = SkyCoord(
                        ra=(config['point_center']['ra'] + params['del_ra']) * u.degree, 
                        dec=(config['point_center']['dec'] + params['del_dec']) * u.degree, 
                        frame="icrs"
                    )
                I, Q, U, V = get_IQUV_complex(
                            freqs, 
                            params['rm'],
                            params['ref_I_Jy'],
                            params['ref_V_Jy'],
                            params['SI'],
                            params['frac_pol'],
                            ref_chi=0.0,
                            ref_freq=params['ref_freq']
                        )

                f.write(f"SOURCE {s} {source_coords.ra.hour} {source_coords.dec.deg}\n")
                for i, freq in enumerate(freqs):
                    f.write(
                         f"FREQ {freq:.6e} {I[i].real:.5f} {Q[i].real:.5f} {U[i].real:.5f} {V[i].real:.5f}\n"
                     )
                f.write('ENDSOURCE\n')

    # Write calibration srclist
    sim_srclist_name = f"{Path(args.out_dir)}/{config['obsid']}_{yaml_cfg.stem}_sim.txt"
    with open(sim_srclist_name, "w") as f:
        for s, params in config['sources'].items():
            source_coords = SkyCoord(
                    ra=(config['point_center']['ra'] + params['del_ra']) * u.degree, 
                    dec=(config['point_center']['dec'] + params['del_dec']) * u.degree, 
                    frame="icrs"
                )
            I, Q, U, V = get_IQUV_complex(
                        freqs, 
                        params['rm'],
                        params['ref_I_Jy'],
                        params['ref_V_Jy'],
                        params['SI'],
                        params['frac_pol'],
                        ref_chi=0.0,
                        ref_freq=params['ref_freq']
                    )

            f.write(f"SOURCE {s} {source_coords.ra.hour} {source_coords.dec.deg}\n")
            for i, freq in enumerate(freqs):
                f.write(
                     f"FREQ {freq:.6e} {I[i].real:.5f} {Q[i].real:.5f} {U[i].real:.5f} {V[i].real:.5f}\n"
                 )
            f.write('ENDSOURCE\n')
