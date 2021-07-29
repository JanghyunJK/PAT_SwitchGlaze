#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see your EnergyPlus installation or the URL below for information on EnergyPlus objects
# http://apps1.eere.energy.gov/buildings/energyplus/pdfs/inputoutputreference.pdf

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on workspace objects (click on "workspace" in the main window to view workspace objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/utilities/html/idf_page.html

$allchoices = 'All fenestration surfaces'

#start the measure
class AInjectWindowSpecificIDFObjects < OpenStudio::Ruleset::WorkspaceUserScript

  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return " Inject Window Specific IDF Objects"
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    glzsys = OpenStudio::StringVector.new
    glzsys << "Single_Pane"
    glzsys << "Double_Pane"
    glzsys << "Triple_Pane"
    glzsys << "VIG"
    glzsys << "ASHRAE_Detailed"
    glzsys << "Static"
    glzsys << "SwitchGlaze"
    
    glztype = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('glztype', glzsys, true)
    glztype.setDisplayName("Choice of IGU")
    glztype.setDefaultValue("SwitchGlaze")
    args << glztype
    
    #make choice arguments for fenestration surface
    fenestrationsurfaces = workspace.getObjectsByType("FenestrationSurface:Detailed".to_IddObjectType)
    chs = OpenStudio::StringVector.new
    fenestrationsurfaces.each do |fenestrationsurface|
      chs << fenestrationsurface.name.to_s
    end
    chs << $allchoices
    chs << "inferred"
    choice = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('choice', chs, true)
    choice.setDisplayName("Choice of window")
    choice.setDefaultValue($allchoices)
    args << choice
    
    # path to the folder that includes idf files containing window objects
    idf_path = OpenStudio::Ruleset::OSArgument.makeStringArgument("idf_path", true)
    idf_path.setDisplayName("path to the folder that includes idf files containing window objects")
    idf_path.setDefaultValue('C:\SpectralIDFs')
    args << idf_path
    
    # thermochromic window switching temperature
    t_switching = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("t_switching", true)
    t_switching.setDisplayName("Switching temperature of a thermochromic window")
    t_switching.setDescription('Only applicable when thermochromic window is selected')
    t_switching.setUnits("C")
    t_switching.setDefaultValue(35)
    args << t_switching
    
    # 
    serverrun = OpenStudio::Ruleset::OSArgument::makeBoolArgument('serverrun', false)
    serverrun.setDisplayName('Running on the server (and not in local)?')
    serverrun.setDefaultValue('false')
    serverrun.setDescription('Select if simulation is being ran on the server')
    args << serverrun

    return args
  end
  
  def check_upstream_measure_for_arg(runner, arg_name)
    # 2.x methods (currently setup for measure display name but snake_case arg names)
    arg_name_value = {}
    runner.workflow.workflowSteps.each do |step|
      if step.to_MeasureStep.is_initialized
        measure_step = step.to_MeasureStep.get
        measure_name = measure_step.measureDirName

        #runner.registerInfo("DEBUGGING: measure_name = #{measure_name}")

        if measure_step.name.is_initialized
          measure_name = measure_step.name.get # this is instance name in PAT
        end
        if measure_step.result.is_initialized
          result = measure_step.result.get
          result.stepValues.each do |arg|
            name = arg.name
            value = arg.valueAsVariant.to_s

            #runner.registerInfo("DEBUGGING: name = #{name}")
            #runner.registerInfo("DEBUGGING: value = #{value}")

            if name == arg_name
              arg_name_value[:value] = value
              arg_name_value[:measure_name] = measure_name
              return arg_name_value # stop after find first one
            end
          end
        else
          # puts "No result for #{measure_name}"
        end
      else
        # puts "This step is not a measure"
      end
    end

    return arg_name_value
  end

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end
    
    ####################################################################################
    # assign the user inputs to variables
    ####################################################################################
    choice = runner.getStringArgumentValue('choice',user_arguments)
    glztype = runner.getStringArgumentValue('glztype',user_arguments)
    serverrun = runner.getBoolArgumentValue('serverrun',user_arguments)
    idf_path = runner.getStringArgumentValue('idf_path',user_arguments)
    t_switching = runner.getDoubleArgumentValue('t_switching',user_arguments)
    ####################################################################################
    
    dictionary_weather = Hash.new
    dictionary_weather = {
      'USA_AK_Fairbanks.Intl.AP.702610_TMY3.epw' => 'VeryCold',
      'USA_MN_International.Falls.Intl.AP.727470_TMY3.epw' => 'VeryCold',
      'USA_WI_Milwaukee-Mitchell.Intl.AP.726400_TMY3.epw' => 'Cold',
      'USA_NM_Albuquerque.Intl.AP.723650_TMY3.epw' => 'Cold',
      'USA_NY_Buffalo-Greater.Buffalo.Intl.AP.725280_TMY3.epw' => 'Cold',
      'USA_CO_Denver.Intl.AP.725650_TMY3.epw' => 'Cold',
      'USA_MT_Great.Falls.Intl.AP.727750_TMY3.epw' => 'Cold',
      'DEU_Hamburg.101470_IWEC.epw' => 'Cold',
      'USA_NY_New.York-J.F.Kennedy.Intl.AP.744860_TMY3.epw' => 'Cold',
      'USA_MN_Rochester.Intl.AP.726440_TMY3.epw' => 'Cold',
      'USA_WA_Seattle-Tacoma.Intl.AP.727930_TMY3.epw' => 'Cold',
      'JPN_Tokyo.Hyakuri.477150_IWEC.epw' => 'Cold',
      'USA_WA_Port.Angeles-William.R.Fairchild.Intl.AP.727885_TMY3.epw' => 'Cold',
      'USA_GA_Atlanta-Hartsfield-Jackson.Intl.AP.722190_TMY3.epw' => 'Hot',
      'USA_TX_El.Paso.Intl.AP.722700_TMY3.epw' => 'Hot',
      'USA_CA_San.Diego-Lindbergh.Field.722900_TMY3.epw' => 'Hot',
      'USA_HI_Honolulu.Intl.AP.911820_TMY3.epw' => 'VeryHot',
      'SAU_Riyadh.404380_IWEC.epw' => 'VeryHot',
      'SGP_Singapore.486980_IWEC.epw' => 'VeryHot',
      'USA_FL_Tampa.Intl.AP.722110_TMY3.epw' => 'VeryHot',
      'USA_AZ_Tucson.Intl.AP.722740_TMY3.epw' => 'VeryHot'
    }
    
    ####################################################################################
    ####################################################################################
    
    # check if thermochromic was defined in upstream measure AddThermochromicBIPV
    pce_scenario = check_upstream_measure_for_arg(runner, 'pce_scenario')
    pce_scenario = pce_scenario[:value]
    if not pce_scenario.nil? || pce_scenario.empty?
      runner.registerInfo("PV PCE scenario type defined in AddThermochromicBIPV measure = #{pce_scenario}")
    end
        
    if pce_scenario=='SwitchGlaze'
      pce_scenario = true
    elsif pce_scenario=='Static'
      pce_scenario = false
    end
    
    pv_eff_fixed = check_upstream_measure_for_arg(runner, 'pv_eff')
    pv_eff_fixed = pv_eff_fixed[:value]
    if not pv_eff_fixed.nil? || pv_eff_fixed.empty?
      runner.registerInfo("Fixed PCE (if PCE variation is not applied) = #{pv_eff_fixed}")
    end
    
    # check PV orientation from upstream measure AddThermochromicBIPV
    pv_orientation = check_upstream_measure_for_arg(runner, 'facade')
    pv_orientation = pv_orientation[:value]
    if not pv_orientation.nil? || pv_orientation.empty?
      runner.registerInfo("PV orientation defined in AddThermochromicBIPV measure = #{pv_orientation}")
    end
    
    t_switching = check_upstream_measure_for_arg(runner, 'switch_t')
    t_switching = t_switching[:value]
    if not t_switching.nil? || t_switching.empty?
      runner.registerInfo("Thermochromic switching temperature defiend in AddThermochromicBIPV measure = #{t_switching}")
      t_switching = t_switching.to_f
    end
    
    ####################################################################################
    ####################################################################################
    
    if glztype == "ASHRAE_Simplified"
    
      runner.registerInfo("Skipping this measure since using Baseline ASHRAE window.")
      return false
      
    elsif (glztype == "ASHRAE_Detailed")
    
      glztype = "ASHRAE"
      
      location = check_upstream_measure_for_arg(runner, 'weather_file_name')
      location = location[:value].split("\\")[-1]
      runner.registerInfo("Weather file defined in the upstream = #{location}")
      
      climateregion = dictionary_weather[location]
      runner.registerInfo("Simple climate classification for this location = #{climateregion}")
  
      glztype = climateregion.concat("_#{glztype.to_s}")
      runner.registerInfo("Window name to be implemented = #{glztype}")
                    
    elsif (glztype == "SwitchGlaze")
    
      glztype = "SG"
      
      location = check_upstream_measure_for_arg(runner, 'weather_file_name')
      location = location[:value].split("\\")[-1]
      runner.registerInfo("Weather file defined in the upstream = #{location}")
      
      climateregion = dictionary_weather[location]
      runner.registerInfo("Simple climate classification for this location = #{climateregion}")
      
      iqe = check_upstream_measure_for_arg(runner, 'iqe')
      iqe = iqe[:value]
      runner.registerInfo("Tint and IQE setting = #{iqe}")
  
      glztype = climateregion.concat("_#{glztype.to_s}")
      iqe = iqe.sub("Tnt_", "")
      glztype = glztype.concat("_"+iqe) #specific string for tinted 1 window files

      runner.registerInfo("glztype = #{glztype}")
      runner.registerInfo("Window name to be implemented = #{glztype}")
    
    elsif (glztype == "Static")

      glztype=""
          
      location = check_upstream_measure_for_arg(runner, 'weather_file_name')
      location = location[:value].split("\\")[-1]
      runner.registerInfo("Weather file defined in the upstream = #{location}")
      
      climateregion = dictionary_weather[location]
      runner.registerInfo("Simple climate classification for this location = #{climateregion}")
      
      iqe = check_upstream_measure_for_arg(runner, 'iqe')
      iqe = iqe[:value]
      runner.registerInfo("Tint and IQE setting = #{iqe}")
  
      glztype = climateregion.concat("#{glztype.to_s}")
      glztype = glztype.concat("_"+iqe) #specific string for tinted 1 window files

      runner.registerInfo("glztype = #{glztype}")
      runner.registerInfo("Window name to be implemented = #{glztype}")
                         
    end
    

    # report initial condition
    runner.registerInitialCondition("The initial IDF file had #{workspace.objects.size} objects.")

    # load IDF
    prefix = ''
    if serverrun==true
      prefix = "../../../lib/resources"
      runner.registerInfo("Reading window idf from: #{prefix}")
      idfpath = prefix + "/" + glztype + ".idf"
    else serverrun==false
      prefix = "#{idf_path}"
      runner.registerInfo("Reading window idf from: #{prefix}")
      idfpath = prefix + "/" + glztype + ".idf"
    end
    
    runner.registerInfo("Reading window idf of: #{idfpath}")
    source_idf = OpenStudio::IdfFile::load(OpenStudio::Path.new(idfpath)).get

    # add everything from the file
    workspace.addObjects(source_idf.objects)    

    runner.registerInitialCondition("Imposing fenestration construction name change on #{choice} surface(s).")
 
    ####################################################################################
    #find the fenestration surface to change
    ####################################################################################
    
    no_found = true
    applicable = true
    fenestrationsurfaces = workspace.getObjectsByType("FenestrationSurface:Detailed".to_IddObjectType)
    fenestrationsurfaces.each do |fenestrationsurface|
    
      if choice == "inferred"
        no_found = false
        ###############################################################
        # getting vertices for window surfaces
        ###############################################################
        v1x=fenestrationsurface.getString(9).get.to_f
        v1y=fenestrationsurface.getString(10).get.to_f
        v1z=fenestrationsurface.getString(11).get.to_f
        v2x=fenestrationsurface.getString(12).get.to_f
        v2y=fenestrationsurface.getString(13).get.to_f
        v2z=fenestrationsurface.getString(14).get.to_f
        # v3x=fenestrationsurface.getString(15).get.to_f
        # v3y=fenestrationsurface.getString(16).get.to_f
        # v3z=fenestrationsurface.getString(17).get.to_f
        v4x=fenestrationsurface.getString(18).get.to_f
        v4y=fenestrationsurface.getString(19).get.to_f
        v4z=fenestrationsurface.getString(20).get.to_f
        ###############################################################
        # surface normal calculation for determining surface orientation between East, North, South, and West
        ###############################################################
        u_x = v2x - v1x
        u_y = v2y - v1y
        u_z = v2z - v1z
        w_x = v4x - v1x
        w_y = v4y - v1y
        w_z = v4z - v1z
        surfacenormal_x = u_y*w_z - u_z*w_y
        surfacenormal_y = u_z*w_x - u_x*w_z
        runner.registerInfo("surfacenormal_x = #{surfacenormal_x}")
        runner.registerInfo("surfacenormal_y = #{surfacenormal_y}")
        surfacenormal_orientation=''
        if (surfacenormal_x>0) && (surfacenormal_y==0)
          surfacenormal_orientation = "E"
        elsif (surfacenormal_x<0) && (surfacenormal_y==0)
          surfacenormal_orientation = "W"
        elsif (surfacenormal_x==0) && (surfacenormal_y>0)
          surfacenormal_orientation = "N"
        elsif (surfacenormal_x==0) && (surfacenormal_y<0)
          surfacenormal_orientation = "S"
        elsif
          false
        end
        runner.registerInfo("surfacenormal_orientation = #{surfacenormal_orientation}")
        ###############################################################
        if pv_orientation.to_s.eql?("S") && (surfacenormal_orientation.to_s.eql?("S"))
          runner.registerInfo("Replacing window on #{fenestrationsurface.getString(0).to_s} which is on #{pv_orientation} orientation") 
          runner.registerInfo("Changing [#{fenestrationsurface.getString(2)}] to [#{glztype}]")
          fenestrationsurface.setString(2,glztype)
        elsif pv_orientation.to_s.eql?("E") && (surfacenormal_orientation.to_s.eql?("E"))
          runner.registerInfo("Replacing window on #{fenestrationsurface.getString(0).to_s} which is on #{pv_orientation} orientation") 
          runner.registerInfo("Changing [#{fenestrationsurface.getString(2)}] to [#{glztype}]")
          fenestrationsurface.setString(2,glztype)
        elsif pv_orientation.to_s.eql?("N") && (surfacenormal_orientation.to_s.eql?("N"))
          runner.registerInfo("Replacing window on #{fenestrationsurface.getString(0).to_s} which is on #{pv_orientation} orientation") 
          runner.registerInfo("Changing [#{fenestrationsurface.getString(2)}] to [#{glztype}]")
          fenestrationsurface.setString(2,glztype)
        elsif pv_orientation.to_s.eql?("W") && (surfacenormal_orientation.to_s.eql?("W"))
          runner.registerInfo("Replacing window on #{fenestrationsurface.getString(0).to_s} which is on #{pv_orientation} orientation") 
          runner.registerInfo("Changing [#{fenestrationsurface.getString(2)}] to [#{glztype}]")
          fenestrationsurface.setString(2,glztype)
        elsif pv_orientation.to_s.eql?("ESW") && !(surfacenormal_orientation.to_s.eql?("N"))
          runner.registerInfo("Replacing window on #{fenestrationsurface.getString(0).to_s} which is on #{pv_orientation} orientation") 
          runner.registerInfo("Changing [#{fenestrationsurface.getString(2)}] to [#{glztype}]")
          fenestrationsurface.setString(2,glztype)
        elsif pv_orientation.to_s.eql?("NONE")
          #do nothing
        elsif pv_orientation.to_s.eql?("ALL")
          runner.registerInfo("Replacing window on #{fenestrationsurface.getString(0).to_s}") 
          runner.registerInfo("Changing [#{fenestrationsurface.getString(2)}] to [#{glztype}]")
          fenestrationsurface.setString(2,glztype)
        end
        ###############################################################
      else
        if fenestrationsurface.getString(0).to_s.eql?(choice) || choice.eql?($allchoices)
          no_found = false
          if applicable  #skip the modeling procedure if the model is not supported
            runner.registerInfo("Replacing window on #{fenestrationsurface.getString(0).to_s}")
            runner.registerInfo("Changing [#{fenestrationsurface.getString(2)}] to [#{glztype}]")
            fenestrationsurface.setString(2,glztype)
          
            #fenestrationsurface.setString(6,"ASHRAE_zone78-Frame") #TODO: change this more interactively/automatically
          
          end
        end
      end
    end
        
    ####################################################################################
    #find the thermochromic object and replace switching temperature based on input
    ####################################################################################
    if pce_scenario==true 
      applicable = true
      tcglazings = workspace.getObjectsByType("WindowMaterial:GlazingGroup:Thermochromic".to_IddObjectType)
      tcglazings.each do |tcglazing|
        if tcglazing.getString(0).to_s.eql?("TCGlazing")
          no_found = false
          runner.registerInfo("Matching the pre-defined thermochromic object name =  #{tcglazing.getString(0)}")
          if applicable  #skip the modeling procedure if the model is not supported
            runner.registerInfo("Changing thermochromic switching temperature to #{t_switching}C")
            tcglazing.setString(1,(t_switching-0.5).to_s)
            tcglazing.setString(3,(t_switching).to_s)
                      
          end
        end
      end
    end
        
    ####################################################################################
    #give an error for the name if no surface is changed
    ####################################################################################
    if no_found
      runner.registerError("Measure #{name} cannot find #{choice}. Exiting......")
      return false
    elsif applicable
      # report final condition of workspace
      runner.registerFinalCondition("Imposed fenestration construction name change on #{choice}.")
    else
      runner.registerAsNotApplicable("#{name} is not running for #{choice} because of inapplicability. Skipping......")
    end
    
    # report final condition
    runner.registerFinalCondition("The final IDF file had #{workspace.objects.size} objects.")

    return true

  end

end

#this allows the measure to be use by the application
AInjectWindowSpecificIDFObjects.new.registerWithApplication

