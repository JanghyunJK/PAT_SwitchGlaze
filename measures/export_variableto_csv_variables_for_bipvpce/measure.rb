require 'erb'
require 'csv'

#start the measure
class ExportVariabletoCSVVariablesForBIPVPCE < OpenStudio::Ruleset::ReportingUserScript

  # human readable name
  def name
    return "ExportVariabletoCSV_VariablesForBIPV_PCE"
  end

  # human readable description
  def description
    return "Exports window's thermochromic specification temperature and incident angle data to a csv file. Associated vertices information are also saved in the csv file."
  end

  # human readable description of modeling approach
  def modeler_description
    return "This measure searches for the window surfaces that has BIPVs and exports variables (thermochromic specification temperature and incident angle) included in the eplusout sql file (Add Output Variable measures should be defined beforehand with output variables: Surface Window Thermochromic Layer Property Specification Temperature & Surface Outside Face Beam Solar Incident Angle Cosine Value) and saves it to a csv file. Vertices information for those surfaces are also saved in the csv file."
  end

  # define the arguments that the user will input
  def arguments()
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for the variable name
    variable_name_first = OpenStudio::Ruleset::OSArgument::makeStringArgument("variable_name_first",true)
    variable_name_first.setDisplayName("Enter First Variable Name.")
    variable_name_first.setDefaultValue("Surface Window Thermochromic Layer Property Specification Temperature")
    args << variable_name_first
    
    variable_name_second = OpenStudio::Ruleset::OSArgument::makeStringArgument("variable_name_second",true)
    variable_name_second.setDisplayName("Enter Second Variable Name.")
    variable_name_second.setDefaultValue("Surface Outside Face Beam Solar Incident Angle Cosine Value")
    args << variable_name_second
	
    #make an argument for the reporting frequency
    reporting_frequency_chs = OpenStudio::StringVector.new
    reporting_frequency_chs << "Hourly"
    reporting_frequency_chs << "Zone Timestep"
    reporting_frequency = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('reporting_frequency', reporting_frequency_chs, true)
    reporting_frequency.setDisplayName("Reporting Frequency.")
    reporting_frequency.setDefaultValue("Zone Timestep")
    args << reporting_frequency 
	
    return args
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking 
    if !runner.validateUserArguments(arguments(), user_arguments)
      return false
    end
	
    #assign the user inputs to variables
    variable_name_first = runner.getStringArgumentValue("variable_name_first",user_arguments)
    variable_name_second = runner.getStringArgumentValue("variable_name_second",user_arguments)
    reporting_frequency = runner.getStringArgumentValue("reporting_frequency",user_arguments) 

	
    #check the user_name for reasonableness
    if variable_name_first == ""
      runner.registerError("No variable name was entered.")
      return false
    end
	
    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get
    
    #########################################################################
    #########################################################################
    #check if there are PV models defined
    generatorpvs = model.getGeneratorPhotovoltaics
    if generatorpvs.empty?
      runner.registerInfo("There are no PVs defined in the model.")
      return false
    end
    #########################################################################
    #########################################################################

    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    sqlFile = sqlFile.get
    model.setSqlFile(sqlFile)
	
    # get the weather file run period (as opposed to design day run period)
    ann_env_pd = nil
    sqlFile.availableEnvPeriods.each do |env_pd|
      env_type = sqlFile.environmentType(env_pd)
      if env_type.is_initialized
        if env_type.get == OpenStudio::EnvironmentType.new("WeatherRunPeriod")
          ann_env_pd = env_pd
          break
        end
      end
    end
    
    #########################################################################
    #########################################################################
    key_values = []
    surface_geometry = []
    generatorpvs.each do |generatorpv|
    
      runner.registerInfo("################################################")
      surfacename = generatorpv.surface.get.name.to_s.split(" - ")[1].upcase
      simplepv = generatorpv.photovoltaicPerformance.to_PhotovoltaicPerformanceSimple.get
      
      runner.registerInfo("Generator object name = #{generatorpv.name}")
      runner.registerInfo("Associated surface name = #{surfacename}")
      runner.registerInfo("Associated BIPV name = #{generatorpv.photovoltaicPerformance.name}")
      
      sub_surfaces = model.getSubSurfaces
      sub_surfaces.each do |sub_surface|
        
        if (sub_surface.outsideBoundaryCondition == 'Outdoors') && (sub_surface.subSurfaceType == 'FixedWindow') && (sub_surface.name.to_s.upcase == surfacename)
          key_values << surfacename
          runner.registerInfo("Found the same surface name in subsurface object = #{sub_surface.name.to_s.upcase}")
          
          azimuth = OpenStudio::Quantity.new(sub_surface.azimuth,OpenStudio::createSIAngle)
          azimuth = OpenStudio::convert(azimuth,OpenStudio::createIPAngle).get.value
          
          # vertices = sub_surface.vertices
          # vertices.each do |vertex|
            # x = vertex.x
            # y = vertex.y
            # z = vertex.z
            
            # surface_geometry << [x,y,z]

            # runner.registerInfo("x-vertex = #{x} / y-vertex = #{y} / z-vertex = #{z}")
          # end
          
          runner.registerInfo("azimuth = #{azimuth}")
          surface_geometry << azimuth
          
        end
      end
    end
    runner.registerInfo("################################################")
    #########################################################################
    #########################################################################
    
    variable_names = sqlFile.availableVariableNames(ann_env_pd, reporting_frequency)
    
    #########################################################################
    #########################################################################
    if !variable_names.include? "#{variable_name_first}"	  
      runner.registerError("#{variable_name_first} is not in sqlFile.  Please add an AddOutputVariable reporting measure with this variable and run again.")
    else		
      headers_variable = ["#{reporting_frequency}"]
      # headers_vertex1_x = ["Vertex1-x"]
      # headers_vertex1_y = ["Vertex1-y"]
      # headers_vertex1_z = ["Vertex1-z"]
      # headers_vertex2_x = ["Vertex2-x"]
      # headers_vertex2_y = ["Vertex2-y"]
      # headers_vertex2_z = ["Vertex2-z"]
      # headers_vertex3_x = ["Vertex3-x"]
      # headers_vertex3_y = ["Vertex3-y"]
      # headers_vertex3_z = ["Vertex3-z"]
      # headers_vertex4_x = ["Vertex4-x"]
      # headers_vertex4_y = ["Vertex4-y"]
      # headers_vertex4_z = ["Vertex4-z"]
      headers_azimuth = ['Azimuth']
      output_timeseries = {}
      
      if key_values.size == 0
         runner.registerError("Timeseries for #{variable_name_first} did not have any key values. No timeseries available.")
      end
      
      surf_i=0
      key_values.each do |key_value|
        timeseries = sqlFile.timeSeries(ann_env_pd, reporting_frequency, variable_name_first.to_s, key_value.to_s)
        if !timeseries.empty?
          timeseries = timeseries.get
          units = timeseries.units
          headers_variable << "#{key_value.to_s}:#{variable_name_first.to_s}[#{units}]"
          # headers_vertex1_x << surface_geometry[surf_i][0]
          # headers_vertex1_y << surface_geometry[surf_i][1]
          # headers_vertex1_z << surface_geometry[surf_i][2]
          # headers_vertex2_x << surface_geometry[surf_i+1][0]
          # headers_vertex2_y << surface_geometry[surf_i+1][1]
          # headers_vertex2_z << surface_geometry[surf_i+1][2]
          # headers_vertex3_x << surface_geometry[surf_i+2][0]
          # headers_vertex3_y << surface_geometry[surf_i+2][1]
          # headers_vertex3_z << surface_geometry[surf_i+2][2]
          # headers_vertex4_x << surface_geometry[surf_i+3][0]
          # headers_vertex4_y << surface_geometry[surf_i+3][1]
          # headers_vertex4_z << surface_geometry[surf_i+3][2]
          headers_azimuth << surface_geometry[surf_i]
          
          output_timeseries[headers_variable[-1]] = timeseries
        else 
          runner.registerWarning("Timeseries for #{key_value} #{variable_name_first} is empty.")
        end	
        # surf_i+=4    
        surf_i+=1
      end
            
      csv_array = []
      # csv_array << headers_vertex1_x
      # csv_array << headers_vertex1_y
      # csv_array << headers_vertex1_z
      # csv_array << headers_vertex2_x
      # csv_array << headers_vertex2_y
      # csv_array << headers_vertex2_z
      # csv_array << headers_vertex3_x
      # csv_array << headers_vertex3_y
      # csv_array << headers_vertex3_z
      # csv_array << headers_vertex4_x
      # csv_array << headers_vertex4_y
      # csv_array << headers_vertex4_z
      csv_array << headers_azimuth
      csv_array << headers_variable
      date_times = output_timeseries[output_timeseries.keys[0]].dateTimes
      
      values = {}
      for key in output_timeseries.keys
        values[key] = output_timeseries[key].values
      end
      
      num_times = date_times.size - 1
      for i in 0..num_times
        date_time = date_times[i]
        row = []
        row << date_time
        for key in headers_variable[1..-1]
        value = values[key][i]
        row << value
        end
        csv_array << row
      end
      
      report_path = "./report_#{variable_name_first.delete(' ')}_#{reporting_frequency.delete(' ')}.csv"
      FileUtils.rm_f(report_path) if File.exist?(report_path)
      csv = CSV.open(report_path, 'w')
      
      csv_array.each do |elem|
        csv << elem
      end
    
    end
    #########################################################################
    #########################################################################
    if !variable_names.include? "#{variable_name_second}"	  
      runner.registerError("#{variable_name_second} is not in sqlFile.  Please add an AddOutputVariable reporting measure with this variable and run again.")
    else		
      headers_variable = ["#{reporting_frequency}"]
      # headers_vertex1_x = ["Vertex1-x"]
      # headers_vertex1_y = ["Vertex1-y"]
      # headers_vertex1_z = ["Vertex1-z"]
      # headers_vertex2_x = ["Vertex2-x"]
      # headers_vertex2_y = ["Vertex2-y"]
      # headers_vertex2_z = ["Vertex2-z"]
      # headers_vertex3_x = ["Vertex3-x"]
      # headers_vertex3_y = ["Vertex3-y"]
      # headers_vertex3_z = ["Vertex3-z"]
      # headers_vertex4_x = ["Vertex4-x"]
      # headers_vertex4_y = ["Vertex4-y"]
      # headers_vertex4_z = ["Vertex4-z"]
      headers_azimuth = ['Azimuth']
      output_timeseries = {}
      
      if key_values.size == 0
         runner.registerError("Timeseries for #{variable_name_second} did not have any key values. No timeseries available.")
      end
      
      surf_i=0
      key_values.each do |key_value|
        timeseries = sqlFile.timeSeries(ann_env_pd, reporting_frequency, variable_name_second.to_s, key_value.to_s)
        if !timeseries.empty?
          timeseries = timeseries.get
          units = timeseries.units
          headers_variable << "#{key_value.to_s}:#{variable_name_second.to_s}[#{units}]"
          # headers_vertex1_x << surface_geometry[surf_i][0]
          # headers_vertex1_y << surface_geometry[surf_i][1]
          # headers_vertex1_z << surface_geometry[surf_i][2]
          # headers_vertex2_x << surface_geometry[surf_i+1][0]
          # headers_vertex2_y << surface_geometry[surf_i+1][1]
          # headers_vertex2_z << surface_geometry[surf_i+1][2]
          # headers_vertex3_x << surface_geometry[surf_i+2][0]
          # headers_vertex3_y << surface_geometry[surf_i+2][1]
          # headers_vertex3_z << surface_geometry[surf_i+2][2]
          # headers_vertex4_x << surface_geometry[surf_i+3][0]
          # headers_vertex4_y << surface_geometry[surf_i+3][1]
          # headers_vertex4_z << surface_geometry[surf_i+3][2]
          headers_azimuth << surface_geometry[surf_i]
          
          output_timeseries[headers_variable[-1]] = timeseries
        else 
          runner.registerWarning("Timeseries for #{key_value} #{variable_name_first} is empty.")
        end	
        # surf_i+=4    
        surf_i+=1     
      end
      
      csv_array = []
      # csv_array << headers_vertex1_x
      # csv_array << headers_vertex1_y
      # csv_array << headers_vertex1_z
      # csv_array << headers_vertex2_x
      # csv_array << headers_vertex2_y
      # csv_array << headers_vertex2_z
      # csv_array << headers_vertex3_x
      # csv_array << headers_vertex3_y
      # csv_array << headers_vertex3_z
      # csv_array << headers_vertex4_x
      # csv_array << headers_vertex4_y
      # csv_array << headers_vertex4_z
      csv_array << headers_azimuth
      csv_array << headers_variable
      date_times = output_timeseries[output_timeseries.keys[0]].dateTimes
      
      values = {}
      for key in output_timeseries.keys
        values[key] = output_timeseries[key].values
      end
      
      num_times = date_times.size - 1
      for i in 0..num_times
        date_time = date_times[i]
        row = []
        row << date_time
        for key in headers_variable[1..-1]
        value = values[key][i]
        row << value
        end
        csv_array << row
      end
      
      report_path = "./report_#{variable_name_second.delete(' ')}_#{reporting_frequency.delete(' ')}.csv"
      FileUtils.rm_f(report_path) if File.exist?(report_path)
      csv = CSV.open(report_path, 'w')
      
      csv_array.each do |elem|
        csv << elem
      end
    
    end
    #########################################################################
    #########################################################################
	
    # close the sql file
    sqlFile.close()

    return true
 
  end

end

# register the measure to be used by the application
ExportVariabletoCSVVariablesForBIPVPCE.new.registerWithApplication
