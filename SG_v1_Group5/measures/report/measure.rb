# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'erb'

# start the measure
class Report < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Report'
  end

  # human readable description
  def description
    return ''
  end

  # human readable description of modeling approach
  def modeler_description
    return ''
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    return args
  end

  # define the outputs that the measure will create
  def outputs
    outs = OpenStudio::Measure::OSOutputVector.new
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('total_pv') # GJ
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_area_ft') # ft^2
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('total_electricity')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('total_electricity_heating')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('total_electricity_cooling')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('total_electricity_lighting')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('total_gas')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('total_gas_heating')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_jan')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_feb')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_mar')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_apr')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_may')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_jun')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_jul')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_aug')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_sep')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_oct')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_nov')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_dec')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_jan')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_feb')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_mar')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_apr')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_may')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_jun')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_jul')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_aug')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_sep')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_oct')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_nov')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_dec')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_jan')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_feb')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_mar')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_apr')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_may')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_jun')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_jul')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_aug')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_sep')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_oct')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_nov')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_dec')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_jan')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_feb')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_mar')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_apr')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_may')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_jun')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_jul')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_aug')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_sep')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_oct')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_nov')
    outs << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_dec')

    # this measure does not produce machine readable outputs with registerValue, return an empty list

    return outs
  end

  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  # Warning: Do not change the name of this method to be snake_case. The method must be lowerCamelCase.
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)
    
    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get
    
    # use the built-in error checking 
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    else
      runner.registerInfo("Sql file not empty")
    end
    sqlFile = sqlFile.get
    model.setSqlFile(sqlFile)
    
    #####################################################################################
    #CHECK: https://openstudio-sdk-documentation.s3.amazonaws.com/cpp/OpenStudio-2.7.0-doc/utilities/html/classopenstudio_1_1_sql_file.html
    ts = sqlFile.availableTimeSeries
    envperiod = sqlFile.availableEnvPeriods
    reportfreq = sqlFile.availableReportingFrequencies("RUN PERIOD 1")
    total_electricity = sqlFile.electricityTotalEndUses.to_f
    total_electricity_heating = sqlFile.electricityHeating.to_f
    total_electricity_cooling = sqlFile.electricityCooling.to_f
    total_electricity_lighting = sqlFile.electricityInteriorLighting.to_f
    total_gas = sqlFile.naturalGasTotalEndUses.to_f
    total_gas_heating = sqlFile.naturalGasHeating.to_f
    #####################################################################################
    
    # get building PV generation directly from BIPV panels
    # using: [Output:Variable,*,Generator Produced DC Electric Energy,Annual;] from E+
    
    environment = nil
    sqlFile.availableEnvPeriods.each do |env_pd|
      env_type = sqlFile.environmentType(env_pd)
      if env_type.is_initialized
        if env_type.get == OpenStudio::EnvironmentType.new("WeatherRunPeriod")
          environment = env_pd
          break
        end
      end
    end
    timestep_h = "Hourly"
    timestep_m = "Monthly"
    timestep_rp = "RunPeriod"
    	
	  #####################################################################################
    
    time_series_hourly = {}
    time_series_monthly = {}
    time_series_runperiod = {}
    
    building_elec = 0
    building_elec_jan = 0
    building_elec_feb = 0
    building_elec_mar = 0
    building_elec_apr = 0
    building_elec_may = 0
    building_elec_jun = 0
    building_elec_jul = 0
    building_elec_aug = 0
    building_elec_sep = 0
    building_elec_oct = 0
    building_elec_nov = 0
    building_elec_dec = 0
    
    building_gas = 0
    building_gas_jan = 0
    building_gas_feb = 0
    building_gas_mar = 0
    building_gas_apr = 0
    building_gas_may = 0
    building_gas_jun = 0
    building_gas_jul = 0
    building_gas_aug = 0
    building_gas_sep = 0
    building_gas_oct = 0
    building_gas_nov = 0
    building_gas_dec = 0
    
    panel_dc_gen = 0.0
    panel_dc_gen_2 = 0.0
    panel_dc_gen_jan = 0
    panel_dc_gen_feb = 0
    panel_dc_gen_mar = 0
    panel_dc_gen_apr = 0
    panel_dc_gen_may = 0
    panel_dc_gen_jun = 0
    panel_dc_gen_jul = 0
    panel_dc_gen_aug = 0
    panel_dc_gen_sep = 0
    panel_dc_gen_oct = 0
    panel_dc_gen_nov = 0
    panel_dc_gen_dec = 0
    
    light_energy = 0
    light_energy_2 = 0
    light_energy_jan = 0
    light_energy_feb = 0
    light_energy_mar = 0
    light_energy_apr = 0
    light_energy_may = 0
    light_energy_jun = 0
    light_energy_jul = 0
    light_energy_aug = 0
    light_energy_sep = 0
    light_energy_oct = 0
    light_energy_nov = 0
    light_energy_dec = 0
    
    
    #####################################################################################
    # save timeseries electricity/gas consumption
    
    key_value = ""
    
    if sqlFile.timeSeries(environment, timestep_m, "Electricity:Facility", key_value).is_initialized
      time_series_monthly['Electricity'] = sqlFile.timeSeries(environment, timestep_m, "Electricity:Facility", key_value).get.values
    end
    
    if sqlFile.timeSeries(environment, timestep_m, "Gas:Facility", key_value).is_initialized
      time_series_monthly['Gas'] = sqlFile.timeSeries(environment, timestep_m, "Gas:Facility", key_value).get.values
    end
    
    if not time_series_monthly['Electricity'].nil? then
      building_elec_jan += time_series_monthly['Electricity'][0]*1E-9	#J to GJ
      building_elec_feb += time_series_monthly['Electricity'][1]*1E-9	#J to GJ
      building_elec_mar += time_series_monthly['Electricity'][2]*1E-9	#J to GJ
      building_elec_apr += time_series_monthly['Electricity'][3]*1E-9	#J to GJ
      building_elec_may += time_series_monthly['Electricity'][4]*1E-9	#J to GJ
      building_elec_jun += time_series_monthly['Electricity'][5]*1E-9	#J to GJ
      building_elec_jul += time_series_monthly['Electricity'][6]*1E-9	#J to GJ
      building_elec_aug += time_series_monthly['Electricity'][7]*1E-9	#J to GJ
      building_elec_sep += time_series_monthly['Electricity'][8]*1E-9	#J to GJ
      building_elec_oct += time_series_monthly['Electricity'][9]*1E-9	#J to GJ
      building_elec_nov += time_series_monthly['Electricity'][10]*1E-9	#J to GJ
      building_elec_dec += time_series_monthly['Electricity'][11]*1E-9	#J to GJ
    else
      puts 'Failed to find Electricity:Facility'
    end
    
    if not time_series_monthly['Gas'].nil? then
      building_gas_jan += time_series_monthly['Gas'][0]*1E-9	#J to GJ
      building_gas_feb += time_series_monthly['Gas'][1]*1E-9	#J to GJ
      building_gas_mar += time_series_monthly['Gas'][2]*1E-9	#J to GJ
      building_gas_apr += time_series_monthly['Gas'][3]*1E-9	#J to GJ
      building_gas_may += time_series_monthly['Gas'][4]*1E-9	#J to GJ
      building_gas_jun += time_series_monthly['Gas'][5]*1E-9	#J to GJ
      building_gas_jul += time_series_monthly['Gas'][6]*1E-9	#J to GJ
      building_gas_aug += time_series_monthly['Gas'][7]*1E-9	#J to GJ
      building_gas_sep += time_series_monthly['Gas'][8]*1E-9	#J to GJ
      building_gas_oct += time_series_monthly['Gas'][9]*1E-9	#J to GJ
      building_gas_nov += time_series_monthly['Gas'][10]*1E-9	#J to GJ
      building_gas_dec += time_series_monthly['Gas'][11]*1E-9	#J to GJ
    else
      puts 'Failed to find Gas:Facility'
    end
    
    
    ###################################################################
    ###################################################################
    ###################################################################

    # result = OpenStudio::IdfObjectVector.new

    # # To use the built-in error checking we need the model...
    # # get the last model and sql file
    # model = runner.lastOpenStudioModel
    # if model.empty?
      # runner.registerError('Cannot find last model.')
      # return false
    # end
    # model = model.get

    # # use the built-in error checking
    # if !runner.validateUserArguments(arguments(model), user_arguments)
      # return false
    # end

    # request = OpenStudio::IdfObject.load('Output:Variable,,Site Outdoor Air Drybulb Temperature,Hourly;').get
    # result << request

    # return result
  # end

  # # define what happens when the measure is run
  # def run(runner, user_arguments)
    # super(runner, user_arguments)

    # # get the last model and sql file
    # model = runner.lastOpenStudioModel
    # if model.empty?
      # runner.registerError('Cannot find last model.')
      # return false
    # end
    # model = model.get

    # # use the built-in error checking (need model)
    # if !runner.validateUserArguments(arguments(model), user_arguments)
      # return false
    # end

    # sql_file = runner.lastEnergyPlusSqlFile
    # if sql_file.empty?
      # runner.registerError('Cannot find last sql file.')
      # return false
    # end
    # sql_file = sql_file.get
    # model.setSqlFile(sql_file)

    # # put data into the local variable 'output', all local variables are available for erb to use when configuring the input html file

    # output =  'Measure Name = ' << name << '<br>'
    # output << 'Building Name = ' << model.getBuilding.name.get << '<br>' # optional variable
    # output << 'Floor Area = ' << model.getBuilding.floorArea.to_s << '<br>' # double variable
    # output << 'Floor to Floor Height = ' << model.getBuilding.nominalFloortoFloorHeight.to_s << ' (m)<br>' # double variable
    # output << 'Net Site Energy = ' << sql_file.netSiteEnergy.to_s << ' (GJ)<br>' # double variable

    # # read in template
    # html_in_path = "#{File.dirname(__FILE__)}/resources/report.html.in"
    # if File.exist?(html_in_path)
      # html_in_path = html_in_path
    # else
      # html_in_path = "#{File.dirname(__FILE__)}/report.html.in"
    # end
    # html_in = ''
    # File.open(html_in_path, 'r') do |file|
      # html_in = file.read
    # end

    # # get the weather file run period (as opposed to design day run period)
    # ann_env_pd = nil
    # sql_file.availableEnvPeriods.each do |env_pd|
      # env_type = sql_file.environmentType(env_pd)
      # if env_type.is_initialized
        # if env_type.get == OpenStudio::EnvironmentType.new('WeatherRunPeriod')
          # ann_env_pd = env_pd
          # break
        # end
      # end
    # end

    # # only try to get the annual timeseries if an annual simulation was run
    # if ann_env_pd

      # # get desired variable
      # key_value = 'Environment'
      # time_step = 'Hourly' # "Zone Timestep", "Hourly", "HVAC System Timestep"
      # variable_name = 'Site Outdoor Air Drybulb Temperature'
      # output_timeseries = sql_file.timeSeries(ann_env_pd, time_step, variable_name, key_value) # key value would go at the end if we used it.

      # if output_timeseries.empty?
        # runner.registerWarning('Timeseries not found.')
      # else
        # runner.registerInfo('Found timeseries.')
      # end
    # else
      # runner.registerWarning('No annual environment period found.')
    # end

    # # configure template with variable values
    # renderer = ERB.new(html_in)
    # html_out = renderer.result(binding)

    # # write html file
    # html_out_path = './report.html'
    # File.open(html_out_path, 'w') do |file|
      # file << html_out
      # # make sure data is written to the disk one way or the other
      # begin
        # file.fsync
      # rescue StandardError
        # file.flush
      # end
    # end

    # # close the sql file
    # sql_file.close

    # return true
    ###################################################################
    ###################################################################
    ###################################################################
  end
end

# register the measure to be used by the application
Report.new.registerWithApplication
