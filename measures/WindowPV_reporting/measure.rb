# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'erb'
require "#{File.dirname(__FILE__)}/resources/os_lib_helper_methods.rb"

#start the measure
class WindowPVReporting < OpenStudio::Measure::ReportingMeasure

  # human readable name
  def name
    "WindowPV Reporting"
  end

  # human readable description
  def description
    "Report PV"
  end

  # human readable description of modeling approach
  def modeler_description
    "Report measure"
  end

  # define the arguments that the user will input
  def arguments()
    # report measure does not require any user arguments, return an empty list
    args = OpenStudio::Measure::OSArgumentVector.new
  end 
  
  # optional outputs to be displayed in PAT 
  def outputs 
    result = OpenStudio::Measure::OSOutputVector.new
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('total_pv') # GJ
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_area_ft') # ft^2
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('capacity_factor') # ratio
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('total_electricity')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('total_electricity_heating')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('total_electricity_cooling')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('total_electricity_lighting')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('total_gas')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('total_gas_heating')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_jan')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_feb')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_mar')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_apr')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_may')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_jun')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_jul')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_aug')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_sep')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_oct')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_nov')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_dc_gen_dec')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_jan')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_feb')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_mar')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_apr')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_may')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_jun')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_jul')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_aug')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_sep')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_oct')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_nov')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('light_energy_dec')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_jan')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_feb')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_mar')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_apr')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_may')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_jun')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_jul')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_aug')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_sep')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_oct')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_nov')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_elec_dec')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_jan')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_feb')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_mar')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_apr')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_may')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_jun')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_jul')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_aug')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_sep')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_oct')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_nov')
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('building_gas_dec')

    
    return result
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking 
    if !runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

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
    
    #####################################################################################
    #####################################################################################
    # save timeseries PV generation
    series = "Generator Produced DC Electric Energy" # in Joule
    model.getGeneratorPhotovoltaics.each do |gp|
      name_gp = gp.name.get
      key_gp = name_gp.upcase
    
      if not sqlFile.timeSeries(environment, timestep_h, series, key_gp).empty?
        time_series_hourly[name_gp] = sqlFile.timeSeries(environment, timestep_h, series, key_gp).get.values
      end
      
      if not sqlFile.timeSeries(environment, timestep_m, series, key_gp).empty?
        time_series_monthly[name_gp] = sqlFile.timeSeries(environment, timestep_m, series, key_gp).get.values
      end
      
      if not sqlFile.timeSeries(environment, timestep_rp, series, key_gp).empty?
        time_series_runperiod[name_gp] = sqlFile.timeSeries(environment, timestep_rp, series, key_gp).get.values
      end
    
      if not time_series_hourly[name_gp].nil? then
        for i in 0..(time_series_hourly[name_gp].size - 1)
          panel_dc_gen += time_series_hourly[name_gp][i]*1E-9 #J to GJ
        end
      else
        puts 'Failed to find ' + name_gp
      end
    
      if not time_series_monthly[name_gp].nil? then
        # for i in 0..(time_series_monthly[name_gp].size - 1)
          #runner.registerInfo("#{name_gp}	#{i+1}	=	#{time_series_monthly[name_gp][i]*1E-9}")
        # end
        panel_dc_gen_jan += time_series_monthly[name_gp][0]*1E-9	#J to GJ
        panel_dc_gen_feb += time_series_monthly[name_gp][1]*1E-9	#J to GJ
        panel_dc_gen_mar += time_series_monthly[name_gp][2]*1E-9	#J to GJ
        panel_dc_gen_apr += time_series_monthly[name_gp][3]*1E-9	#J to GJ
        panel_dc_gen_may += time_series_monthly[name_gp][4]*1E-9	#J to GJ
        panel_dc_gen_jun += time_series_monthly[name_gp][5]*1E-9	#J to GJ
        panel_dc_gen_jul += time_series_monthly[name_gp][6]*1E-9	#J to GJ
        panel_dc_gen_aug += time_series_monthly[name_gp][7]*1E-9	#J to GJ
        panel_dc_gen_sep += time_series_monthly[name_gp][8]*1E-9	#J to GJ
        panel_dc_gen_oct += time_series_monthly[name_gp][9]*1E-9	#J to GJ
        panel_dc_gen_nov += time_series_monthly[name_gp][10]*1E-9	#J to GJ
        panel_dc_gen_dec += time_series_monthly[name_gp][11]*1E-9	#J to GJ
    
      else
        puts 'Failed to find ' + name_gp
      end
    
      if not time_series_runperiod[name_gp].nil? then
        for i in 0..(time_series_runperiod[name_gp].size - 1)
          panel_dc_gen_2 += time_series_runperiod[name_gp][0]*1E-9	#J to GJ
        end
      else
        puts 'Failed to find ' + name_gp
      end
    
    end
      
    #####################################################################################
    #####################################################################################
    # save timeseries lighting energy
    light_defs = []
    
    space_types = model.getSpaceTypes
    space_types.each do |space_type|
      space_type_lights = space_type.lights
      space_type_lights.each do |space_type_light|
        # runner.registerInfo("space_type_light.name = #{space_type_light.name}")
        light_defs << space_type_light.name.get
      end
    end    
    
    series = "Lights Electric Energy" # in Joule
    spaces = model.getSpaces
    spaces.each do |space|
      # runner.registerInfo("######################################################")
      # runner.registerInfo("spaces.each = #{space}")
      # runner.registerInfo("space.name = #{space.name}")

      name_gp = space.name.get
      key_gp = name_gp.upcase
      
      light_defs.each do |light_def|
        teststring = "ZONE " + key_gp + " " + light_def
        
        # runner.registerInfo("key_gp = #{key_gp}")
        # runner.registerInfo("sqlFile.timeSeries(environment, timestep_h, series, teststring).empty? = #{sqlFile.timeSeries(environment, timestep_h, series, teststring).empty?}")

        if not sqlFile.timeSeries(environment, timestep_h, series, teststring).empty?
          time_series_hourly[name_gp] = sqlFile.timeSeries(environment, timestep_h, series, teststring).get.values
        end
        
        if not sqlFile.timeSeries(environment, timestep_m, series, teststring).empty?
          time_series_monthly[name_gp] = sqlFile.timeSeries(environment, timestep_m, series, teststring).get.values
        end
        
        if not sqlFile.timeSeries(environment, timestep_rp, series, teststring).empty?
          time_series_runperiod[name_gp] = sqlFile.timeSeries(environment, timestep_rp, series, teststring).get.values
        end
      
        if not time_series_hourly[name_gp].nil? then
          for i in 0..(time_series_hourly[name_gp].size - 1)
            light_energy += time_series_hourly[name_gp][i]*1E-9 #J to GJ
          end
        else
          puts 'Failed to find ' + name_gp
        end
      
        if not time_series_monthly[name_gp].nil? then
          # for i in 0..(time_series_monthly[name_gp].size - 1)
            #runner.registerInfo("#{name_gp}	#{i+1}	=	#{time_series_monthly[name_gp][i]*1E-9}")
          # end
          light_energy_jan += time_series_monthly[name_gp][0]*1E-9	#J to GJ
          light_energy_feb += time_series_monthly[name_gp][1]*1E-9	#J to GJ
          light_energy_mar += time_series_monthly[name_gp][2]*1E-9	#J to GJ
          light_energy_apr += time_series_monthly[name_gp][3]*1E-9	#J to GJ
          light_energy_may += time_series_monthly[name_gp][4]*1E-9	#J to GJ
          light_energy_jun += time_series_monthly[name_gp][5]*1E-9	#J to GJ
          light_energy_jul += time_series_monthly[name_gp][6]*1E-9	#J to GJ
          light_energy_aug += time_series_monthly[name_gp][7]*1E-9	#J to GJ
          light_energy_sep += time_series_monthly[name_gp][8]*1E-9	#J to GJ
          light_energy_oct += time_series_monthly[name_gp][9]*1E-9	#J to GJ
          light_energy_nov += time_series_monthly[name_gp][10]*1E-9	#J to GJ
          light_energy_dec += time_series_monthly[name_gp][11]*1E-9	#J to GJ
      
        else
          puts 'Failed to find ' + name_gp
        end
      
        if not time_series_runperiod[name_gp].nil? then
          for i in 0..(time_series_runperiod[name_gp].size - 1)
            light_energy_2 += time_series_runperiod[name_gp][0]*1E-9	#J to GJ
          end
        else
          puts 'Failed to find ' + name_gp
        end
      end
    end
    
    # runner.registerInfo("######################################################")
    # runner.registerInfo("light_energy_jan = #{light_energy_jan}")
    # runner.registerInfo("light_energy = #{light_energy}")
    # runner.registerInfo("light_energy_2 = #{light_energy_2}")
    # runner.registerInfo("total_electricity_lighting #{total_electricity_lighting}")
    # runner.registerInfo("######################################################")     
    #####################################################################################
    #####################################################################################
    
    # total PV generation
    total_pv = panel_dc_gen
    panel_dc_gen_kwh = total_pv * 277.778 # convert GJ --> kWh
    runner.registerInfo("Generator produced DC electric energy (GJ): #{total_pv.round(2)} (#{panel_dc_gen_kwh.round(2)} kWh)")
    runner.registerValue('total_pv', total_pv.round(6), 'GJ')
    #runner.registerValue('panel_dc_gen_kwh', panel_dc_gen_kwh.round(2), 'kWh')

    # total PV generation JAN
    runner.registerInfo("Generator produced DC electric energy (GJ) in JAN: #{panel_dc_gen_jan.round(2)} GJ")
    runner.registerValue('panel_dc_gen_jan', panel_dc_gen_jan.round(2), 'GJ')
	
    # total PV generation FEB
    runner.registerInfo("Generator produced DC electric energy (GJ) in FEB: #{panel_dc_gen_feb.round(2)} GJ")
    runner.registerValue('panel_dc_gen_feb', panel_dc_gen_feb.round(2), 'GJ')
	
    # total PV generation MAR
    runner.registerInfo("Generator produced DC electric energy (GJ) in MAR: #{panel_dc_gen_mar.round(2)} GJ")
    runner.registerValue('panel_dc_gen_mar', panel_dc_gen_mar.round(2), 'GJ')
	
    # total PV generation APR
    runner.registerInfo("Generator produced DC electric energy (GJ) in APR: #{panel_dc_gen_apr.round(2)} GJ")
    runner.registerValue('panel_dc_gen_apr', panel_dc_gen_apr.round(2), 'GJ')
	
    # total PV generation MAY
    runner.registerInfo("Generator produced DC electric energy (GJ) in MAY: #{panel_dc_gen_may.round(2)} GJ")
    runner.registerValue('panel_dc_gen_may', panel_dc_gen_may.round(2), 'GJ')
	
    # total PV generation JUN
    runner.registerInfo("Generator produced DC electric energy (GJ) in JUN: #{panel_dc_gen_jun.round(2)} GJ")
    runner.registerValue('panel_dc_gen_jun', panel_dc_gen_jun.round(2), 'GJ')
	
    # total PV generation JUL
    runner.registerInfo("Generator produced DC electric energy (GJ) in JUL: #{panel_dc_gen_jul.round(2)} GJ")
    runner.registerValue('panel_dc_gen_jul', panel_dc_gen_jul.round(2), 'GJ')
	
    # total PV generation AUG
    runner.registerInfo("Generator produced DC electric energy (GJ) in AUG: #{panel_dc_gen_aug.round(2)} GJ")
    runner.registerValue('panel_dc_gen_aug', panel_dc_gen_aug.round(2), 'GJ')
	
    # total PV generation SEP
    runner.registerInfo("Generator produced DC electric energy (GJ) in SEP: #{panel_dc_gen_sep.round(2)} GJ")
    runner.registerValue('panel_dc_gen_sep', panel_dc_gen_sep.round(2), 'GJ')
	
    # total PV generation OCT
    runner.registerInfo("Generator produced DC electric energy (GJ) in OCT: #{panel_dc_gen_oct.round(2)} GJ")
    runner.registerValue('panel_dc_gen_oct', panel_dc_gen_oct.round(2), 'GJ')
	
    # total PV generation NOV
    runner.registerInfo("Generator produced DC electric energy (GJ) in NOV: #{panel_dc_gen_nov.round(2)} GJ")
    runner.registerValue('panel_dc_gen_nov', panel_dc_gen_nov.round(2), 'GJ')
	
    # total PV generation DEC
    runner.registerInfo("Generator produced DC electric energy (GJ) in DEC: #{panel_dc_gen_dec.round(2)} GJ")
    runner.registerValue('panel_dc_gen_dec', panel_dc_gen_dec.round(2), 'GJ')
    
    ####################################################################################
    
    light_energy_kwh = light_energy * 277.778 # convert GJ --> kWh
    runner.registerInfo("Lighting energy (GJ): #{light_energy.round(2)} (#{light_energy_kwh.round(2)} kWh)")
    runner.registerValue('light_energy', light_energy.round(6), 'GJ')
    
    # total lighting JAN
    runner.registerInfo("Lighting energy (GJ) in JAN: #{light_energy_jan.round(2)} GJ")
    runner.registerValue('light_energy_jan', light_energy_jan.round(2), 'GJ')
	
    # total lighting FEB
    runner.registerInfo("Lighting energy (GJ) in FEB: #{light_energy_feb.round(2)} GJ")
    runner.registerValue('light_energy_feb', light_energy_feb.round(2), 'GJ')
	
    # total lighting MAR
    runner.registerInfo("Lighting energy (GJ) in MAR: #{light_energy_mar.round(2)} GJ")
    runner.registerValue('light_energy_mar', light_energy_mar.round(2), 'GJ')
	
    # total lighting APR
    runner.registerInfo("Lighting energy (GJ) in APR: #{light_energy_apr.round(2)} GJ")
    runner.registerValue('light_energy_apr', light_energy_apr.round(2), 'GJ')
	
    # total lighting MAY
    runner.registerInfo("Lighting energy (GJ) in MAY: #{light_energy_may.round(2)} GJ")
    runner.registerValue('light_energy_may', light_energy_may.round(2), 'GJ')
	
    # total lighting JUN
    runner.registerInfo("Lighting energy (GJ) in JUN: #{light_energy_jun.round(2)} GJ")
    runner.registerValue('light_energy_jun', light_energy_jun.round(2), 'GJ')
	
    # total lighting JUL
    runner.registerInfo("Lighting energy (GJ) in JUL: #{light_energy_jul.round(2)} GJ")
    runner.registerValue('light_energy_jul', light_energy_jul.round(2), 'GJ')
	
    # total lighting AUG
    runner.registerInfo("Lighting energy (GJ) in AUG: #{light_energy_aug.round(2)} GJ")
    runner.registerValue('light_energy_aug', light_energy_aug.round(2), 'GJ')
	
    # total lighting SEP
    runner.registerInfo("Lighting energy (GJ) in SEP: #{light_energy_sep.round(2)} GJ")
    runner.registerValue('light_energy_sep', light_energy_sep.round(2), 'GJ')
	
    # total lighting OCT
    runner.registerInfo("Lighting energy (GJ) in OCT: #{light_energy_oct.round(2)} GJ")
    runner.registerValue('light_energy_oct', light_energy_oct.round(2), 'GJ')
	
    # total lighting NOV
    runner.registerInfo("Lighting energy (GJ) in NOV: #{light_energy_nov.round(2)} GJ")
    runner.registerValue('light_energy_nov', light_energy_nov.round(2), 'GJ')
	
    # total lighting DEC
    runner.registerInfo("Lighting energy (GJ) in DEC: #{light_energy_dec.round(2)} GJ")
    runner.registerValue('light_energy_dec', light_energy_dec.round(2), 'GJ')
    
    ####################################################################################
    
    # total electricity JAN
    runner.registerInfo("Building electricity (GJ) in JAN: #{building_elec_jan.round(2)} GJ")
    runner.registerValue('building_elec_jan', building_elec_jan.round(2), 'GJ')
	
    # total electricity FEB
    runner.registerInfo("Building electricity (GJ) in FEB: #{building_elec_feb.round(2)} GJ")
    runner.registerValue('building_elec_feb', building_elec_feb.round(2), 'GJ')
	
    # total electricity MAR
    runner.registerInfo("Building electricity (GJ) in MAR: #{building_elec_mar.round(2)} GJ")
    runner.registerValue('building_elec_mar', building_elec_mar.round(2), 'GJ')
	
    # total electricity APR
    runner.registerInfo("Building electricity (GJ) in APR: #{building_elec_apr.round(2)} GJ")
    runner.registerValue('building_elec_apr', building_elec_apr.round(2), 'GJ')
	
    # total electricity MAY
    runner.registerInfo("Building electricity (GJ) in MAY: #{building_elec_may.round(2)} GJ")
    runner.registerValue('building_elec_may', building_elec_may.round(2), 'GJ')
	
    # total electricity JUN
    runner.registerInfo("Building electricity (GJ) in JUN: #{building_elec_jun.round(2)} GJ")
    runner.registerValue('building_elec_jun', building_elec_jun.round(2), 'GJ')
	
    # total electricity JUL
    runner.registerInfo("Building electricity (GJ) in JUL: #{building_elec_jul.round(2)} GJ")
    runner.registerValue('building_elec_jul', building_elec_jul.round(2), 'GJ')
	
    # total electricity AUG
    runner.registerInfo("Building electricity (GJ) in AUG: #{building_elec_aug.round(2)} GJ")
    runner.registerValue('building_elec_aug', building_elec_aug.round(2), 'GJ')
	
    # total electricity SEP
    runner.registerInfo("Building electricity (GJ) in SEP: #{building_elec_sep.round(2)} GJ")
    runner.registerValue('building_elec_sep', building_elec_sep.round(2), 'GJ')
	
    # total electricity OCT
    runner.registerInfo("Building electricity (GJ) in OCT: #{building_elec_oct.round(2)} GJ")
    runner.registerValue('building_elec_oct', building_elec_oct.round(2), 'GJ')
	
    # total electricity NOV
    runner.registerInfo("Building electricity (GJ) in NOV: #{building_elec_nov.round(2)} GJ")
    runner.registerValue('building_elec_nov', building_elec_nov.round(2), 'GJ')
	
    # total electricity DEC
    runner.registerInfo("Building electricity (GJ) in DEC: #{building_elec_dec.round(2)} GJ")
    runner.registerValue('building_elec_dec', building_elec_dec.round(2), 'GJ')
    
    ####################################################################################
    
    # total gas JAN
    runner.registerInfo("Building gas (GJ) in JAN: #{building_gas_jan.round(2)} GJ")
    runner.registerValue('building_gas_jan', building_gas_jan.round(2), 'GJ')
	
    # total gas FEB
    runner.registerInfo("Building gas (GJ) in FEB: #{building_gas_feb.round(2)} GJ")
    runner.registerValue('building_gas_feb', building_gas_feb.round(2), 'GJ')
	
    # total gas MAR
    runner.registerInfo("Building gas (GJ) in MAR: #{building_gas_mar.round(2)} GJ")
    runner.registerValue('building_gas_mar', building_gas_mar.round(2), 'GJ')
	
    # total gas APR
    runner.registerInfo("Building gas (GJ) in APR: #{building_gas_apr.round(2)} GJ")
    runner.registerValue('building_gas_apr', building_gas_apr.round(2), 'GJ')
	
    # total gas MAY
    runner.registerInfo("Building gas (GJ) in MAY: #{building_gas_may.round(2)} GJ")
    runner.registerValue('building_gas_may', building_gas_may.round(2), 'GJ')
	
    # total gas JUN
    runner.registerInfo("Building gas (GJ) in JUN: #{building_gas_jun.round(2)} GJ")
    runner.registerValue('building_gas_jun', building_gas_jun.round(2), 'GJ')
	
    # total gas JUL
    runner.registerInfo("Building gas (GJ) in JUL: #{building_gas_jul.round(2)} GJ")
    runner.registerValue('building_gas_jul', building_gas_jul.round(2), 'GJ')
	
    # total gas AUG
    runner.registerInfo("Building gas (GJ) in AUG: #{building_gas_aug.round(2)} GJ")
    runner.registerValue('building_gas_aug', building_gas_aug.round(2), 'GJ')
	
    # total gas SEP
    runner.registerInfo("Building gas (GJ) in SEP: #{building_gas_sep.round(2)} GJ")
    runner.registerValue('building_gas_sep', building_gas_sep.round(2), 'GJ')
	
    # total gas OCT
    runner.registerInfo("Building gas (GJ) in OCT: #{building_gas_oct.round(2)} GJ")
    runner.registerValue('building_gas_oct', building_gas_oct.round(2), 'GJ')
	
    # total gas NOV
    runner.registerInfo("Building gas (GJ) in NOV: #{building_gas_nov.round(2)} GJ")
    runner.registerValue('building_gas_nov', building_gas_nov.round(2), 'GJ')
	
    # total gas DEC
    runner.registerInfo("Building gas (GJ) in DEC: #{building_gas_dec.round(2)} GJ")
    runner.registerValue('building_gas_dec', building_gas_dec.round(2), 'GJ')
    
    ####################################################################################

    # building area
    building_area = model.getBuilding.floorArea
    building_area_ft = OpenStudio.convert(building_area, 'm^2', 'ft^2').get
    #runner.registerInfo("Building Area: #{building_area_ft.round(2)} ft^2")
    runner.registerValue('building_area_ft', building_area_ft.round(2), 'ft^2')

    # capacity factor
    upstream_var = OsLib_HelperMethods.check_upstream_measure_for_arg(runner, 'system_rated_output')
    system_rated_output = upstream_var[:value].to_f
    system_ideal_energy_production = system_rated_output * (31636000*1E-9) # assumed running at peak all seconds in a year, (GJ)
	
    # account for base case (zero output)
    capacity_factor = panel_dc_gen.to_f > 0 ? panel_dc_gen.to_f / system_ideal_energy_production : 0.0 # watts, joules, oh my!
    #runner.registerInfo("Capacity Factor: #{capacity_factor.round(6)}")
    runner.registerValue('capacity_factor', capacity_factor.round(6), '%')
	
    # total electricity consumption for building
    runner.registerInfo("Total Electricity for Building: #{total_electricity.round(2)} GJ")
    runner.registerValue('total_electricity', total_electricity.round(6), 'GJ')
	
    # total electricity consumption for heating
    #runner.registerInfo("Total Electricity for Heating: #{total_electricity_heating.round(6)} GJ")
    runner.registerValue('total_electricity_heating', total_electricity_heating.round(6), 'GJ')
	
    # total electricity consumption for cooling
    #runner.registerInfo("Total Electricity for Cooling: #{total_electricity_cooling.round(6)} GJ")
    runner.registerValue('total_electricity_cooling', total_electricity_cooling.round(6), 'GJ')
	
    # total electricity consumption for lighting
    #runner.registerInfo("Total Electricity for Lighting: #{total_electricity_lighting.round(6)} GJ")
    runner.registerValue('total_electricity_lighting', total_electricity_lighting.round(6), 'GJ')
	
    # total gas consumption for building
    runner.registerInfo("Total Gas for Building: #{total_gas.round(2)} GJ")
    runner.registerValue('total_gas', total_gas.round(6), 'GJ')
	
    # total gas consumption for heating
    #runner.registerInfo("Total Gas for Heating: #{total_gas_heating.round(6)} GJ")
    runner.registerValue('total_gas_heating', total_gas_heating.round(6), 'GJ')
	
    #runner.registerInfo("######################################################")

    #####################################################################################

    # close the sql file
    sqlFile.close()

    return true
 
  end

end

# register the measure to be used by the application
WindowPVReporting.new.registerWithApplication
