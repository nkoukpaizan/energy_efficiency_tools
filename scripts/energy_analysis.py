import sys, os
import numpy as np
import importlib

# Add the tools directory
parent_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, parent_dir)

import tools.analysis_tools as tools

importlib.reload(tools)

def energy_analysis(input_dirs, edp_alpha, edp_beta, local_plot=True, global_plot=True):
    print( f'Input directory: {input_dirs}')
    print( f'EDP alpha: {edp_alpha}')
    print( f'EDP beta: {edp_beta}')
    
    frequency_sweep_data_all = {}
    
    for indx,input_dir in enumerate(input_dirs):
      job_data = tools.load_job_output_file( input_dir ) 
      
      if 'frequency_sweep' in job_data:
        frequency_sweep_data = tools.load_frequency_sweep_data( input_dir )

        if local_plot:
            # Generate the time, energy, and EDP vs frequency cap plots
            figure_name = f'{input_dir}/time_energy_vs_frequency_cap.png'
            title = None
            tools.plot_frequency_cap_energy_analysis( job_data, edp_alpha, edp_beta, figure_name, title=title )
    
        frequency_sweep_data_all[indx] = {'job_data': job_data, 'frequency_sweep_data':frequency_sweep_data }

    if global_plot:
        figure_name = f'frequency_sweep_combined.png'
        title = None
        tools.plot_frequency_cap_energy_analysis(frequency_sweep_data_all, edp_alpha, edp_beta, figure_name, multiple_data=True, title=title )

    return frequency_sweep_data_all