"""
Create RTS style sourclists for calibration & simulations
of polarised sources with given rotation measure
"""

import yaml
import numpy as np
from pathlib import Path
from astropy import units as u
from astropy.coordinates import SkyCoord
from matplotlib import pyplot as plt
from scipy import constants as const

def spectal_index(freqs, SI, ref_flux, ref_freq):
    """Determine flux at frequencies based on SI and ref_freq.

    Parameters
    ----------
    freqs : numpy.array / float
        An array of freqencies in Hz at which flux is to be determined
    SI : float
        Spectral index of source
    ref_flux : float
        Reference flux in Jy
    ref_freq : float
        Reference frequency in HZ

    Returns
    -------
    numpy.array / float
        flux_freqs : An array of fluxes in Jy, for every frequency
    """

    flux_freqs = ref_flux * ((freqs / ref_freq) ** SI)

    return flux_freqs


def pol_angle_lamba(rm, lambdas, ref_chi):
    """Polarization angle as a function of frequency.

    Parameters
    ----------
    rm : float
        Rotation measure of source in [rad m^-2]
    lambdas : numpy.array / float
        Wavelengths in metres
    ref_chi : float
        Reference polarization angle

    Returns
    -------
    numpy.array / float
        Polarization angle at wavelengths
    """

    return ref_chi + rm * lambdas ** 2


def get_IQUV_complex(
    freqs, rm, ref_I_Jy, ref_V_Jy, SI, frac_pol, ref_chi=0.0, ref_freq=200e6
):
    """
    Get I, Q, U stokes parameters as a function of freqency.

    Parameters
    ----------
    freqs : numpy.array / float
        An array of freqencies in Hz at which flux is to be determined
    rm : float
        Rotation measure of source in [rad m^-2]
    ref_I_Jy : float
        Reference flux in Jy of stokes I
    SI : float
        Spectral index of source
    frac_pol : float
        Polarization fraction
    ref_chi : float
        Reference polarization angle, default: 0.0
    ref_freq : float
        Reference frequency in HZ, default : 200e6

    Returns
    -------
    I, Q, U complex stokes parameters as a function of frequency

    Note
    ----
    Modified from Jack Line's beam test script
    """
    lambdas = const.c / freqs

    pol_ang = pol_angle_lamba(rm, lambdas, ref_chi)

    I = spectal_index(freqs, SI, ref_I_Jy, ref_freq)

    numer = frac_pol * I * np.exp(2j * pol_ang)
    denom = 1 + 1j * np.tan(2 * pol_ang)

    Q = numer / denom

    U = Q * np.tan(2 * pol_ang)

    V = spectal_index(freqs, SI, ref_V_Jy, ref_freq=200e6)

    return I, Q, U, V

def rm_synth(freqs, Q, U, phi_lim=200, dphi=0.5):
    """Do RM Synthesis on stokes Q & U vectors.

    Parameters
    ----------
    freqs : numpy.array / float
        An array of freqencies in Hz at which flux is to be determined
    Q, U : numpy.array
        Linear stokes vectors
    phi_lim : float
        Faraday depth limit, default : +-200
    dphi : float
        Faraday depth resolution, default : 0.5

    Returns
    -------
    numpy.array
        FDF (Faraday Dispersion Function)
        RMSF (Rotation Measure Spread Function)
        Phi (Array of faraday depths)
    """

    # Wavelengths
    lambdas = const.c / freqs

    # Uniform weights
    weights = np.ones(Q.shape)

    # Eqn 38 (B&dB 2005)
    K = 1 / np.sum(weights)

    # Eqn 32 (B&dB 2005) - weighted mean on lambda^2
    lam0sq = K * np.sum(weights * lambdas ** 2)

    # Phi array - range of faraday depths
    phi_arr = np.arange(-phi_lim, phi_lim + dphi, dphi)

    # Complex linear polarization
    P = Q + 1j * U

    FDF = K * np.sum(
        P * np.exp(np.outer(-2.0j * phi_arr, (lambdas ** 2 - lam0sq))), axis=1
    )

    RMSF = K * np.sum(
        weights * np.exp(np.outer(-2.0j * phi_arr, (lambdas ** 2 - lam0sq))), axis=1
    )

    return FDF, RMSF, phi_arr

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

    yaml_cfg = args.yaml_cfg

    # Make output dir if it doesn't exist
    Path(args.out_dir).mkdir(parents=True, exist_ok=True)

    with open(yaml_cfg, 'r') as stream:
        config = yaml.load(stream, Loader=yaml.CLoader)
        
    freqs = np.arange(
            config['sim_freqs']['low_freq'], 
            config['sim_freqs']['high_freq'] + config['sim_freqs']['bw'], 
            config['sim_freqs']['bw']
            )

    # Write calibration srclist
    cal_srclist_name = f"{args.out_dir}/{config['obsid']}_{yaml_cfg.split('.')[0]}_cal.txt"
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
    sim_srclist_name = f"{args.out_dir}/{config['obsid']}_{yaml_cfg.split('.')[0]}_sim.txt"
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
