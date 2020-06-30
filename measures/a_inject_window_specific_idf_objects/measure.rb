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
    glzsys << "Baseline_ASHRAE"
    glzsys << "Baseline_GlzSys6"
    glzsys << "Baseline_GlzSys13"
    glzsys << "Baseline_GlzSys15"
    glzsys << "Baseline_GlzSys6_13"
    glzsys << "Baseline_GlzSys15_withPV"
    glzsys << "GlzSys_6_withoutPV"
    glzsys << "GlzSys_13_withoutPV"
    glzsys << "GlzSys_6_withPV"
    glzsys << "GlzSys_13_withPV"
    glzsys << "GlzSys_Dark"
    glzsys << "GlzSys_Light"
    glzsys << "GlzSys_Thermochromic_40C"
    glzsys << "GlzSys_Thermochromic_35C"
    glzsys << "GlzSys_Thermochromic_30C"
    glzsys << "FrameTest_woFrame"
    glzsys << "FrameTest_wFrame"
    glzsys << "VeryHot_ASHRAE"
    glzsys << "VeryHot_SwitchGlaze"
    glzsys << "VeryHot_Dark"
    glzsys << "VeryHot_Light"
    glzsys << "Hot_ASHRAE"
    glzsys << "Hot_SwitchGlaze"
    glzsys << "Hot_Dark"
    glzsys << "Hot_Light"
    glzsys << "Cold_ASHRAE"
    glzsys << "Cold_SwitchGlaze"
    glzsys << "Cold_Dark"
    glzsys << "Cold_Light"
    glzsys << "VeryCold_ASHRAE"
    glzsys << "VeryCold_SwitchGlaze"
    glzsys << "VeryCold_Dark"
    glzsys << "VeryCold_Light"
    
    glztype = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('glztype', glzsys, true)
    glztype.setDisplayName("Choice of IGU")
    glztype.setDefaultValue("Baseline_ASHRAE")
    args << glztype
    
    #make choice arguments for fenestration surface
    fenestrationsurfaces = workspace.getObjectsByType("FenestrationSurface:Detailed".to_IddObjectType)
    chs = OpenStudio::StringVector.new
    fenestrationsurfaces.each do |fenestrationsurface|
      chs << fenestrationsurface.name.to_s
    end
    chs << $allchoices
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
        if measure_step.name.is_initialized
          measure_name = measure_step.name.get # this is instance name in PAT
        end
        if measure_step.result.is_initialized
          result = measure_step.result.get
          result.stepValues.each do |arg|
            name = arg.name
            value = arg.valueAsVariant.to_s
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
    
    # check if thermochromic was defined in upstream measure AddThermochromicBIPV
    thermochromicwindow = check_upstream_measure_for_arg(runner, 'windowscenario')
    thermochromicwindow = thermochromicwindow[:value]
        
    if thermochromicwindow=='SwitchGlaze'
      thermochromicwindow = true
    elsif thermochromicwindow=='Baseline'
      thermochromicwindow = false
    end
    
    ####################################################################################
    runner.registerInfo("##################################################")
    if glztype == "Baseline_ASHRAE"
    
      runner.registerInfo("Skipping this measure since using Baseline ASHRAE window.")
      return false
      
    elsif thermochromicwindow == false
    
      glztype = "ASHRAE"
      
      location = check_upstream_measure_for_arg(runner, 'weather_file_name')
      location = location[:value].split("\\")[-1]
      runner.registerInfo("Weather file defined in the upstream = #{location}")
      
      climateregion = dictionary_weather[location]
      runner.registerInfo("Simple climate classification for this location = #{climateregion}")
  
      glztype = climateregion.concat("_#{glztype.to_s}")
      runner.registerInfo("Window name to be implemented = #{glztype}")
                    
    elsif thermochromicwindow == true
    
      glztype = "SwitchGlaze"
      
      location = check_upstream_measure_for_arg(runner, 'weather_file_name')
      location = location[:value].split("\\")[-1]
      runner.registerInfo("Weather file defined in the upstream = #{location}")
      
      climateregion = dictionary_weather[location]
      runner.registerInfo("Simple climate classification for this location = #{climateregion}")
  
      glztype = climateregion.concat("_#{glztype.to_s}")
      runner.registerInfo("Window name to be implemented = #{glztype}")
           
      t_switching = check_upstream_measure_for_arg(runner, 'switch_t')
      t_switching = t_switching[:value].to_f
    
      runner.registerInfo("Thermochromic switching temperature defined in the AddThermochromicBIPV measure = #{t_switching}C")
     
    end
    runner.registerInfo("##################################################")
    
    
    # Note for setting up dictionary:
    # file names can be anything, but the name of the construction object in the idf file should match with the key of the dictionary, for this setting
    ####################################################################################
    # DIFFERENT DICTIONARIES FOR LOCAL AND SERVER SIMULATION
    ####################################################################################
    dictionary = Hash.new
    
    if serverrun == true
      runner.registerInfo("Reading idf files from the server ../../../lib/resources directory")
      dictionary = {
        "Baseline_GlzSys6" => "../../../lib/resources/GlzSys_16095-air-9_Spec.idf",
        "Baseline_GlzSys13" => "../../../lib/resources/GlzSys_6374-air-3000_Spec.idf",
        "Baseline_GlzSys15" => "../../../lib/resources/GlzSys_10F-air-3000_Spec.idf",
        "Baseline_GlzSys15_withPV" => "../../../lib/resources/GlzSys21_13F-air-3000_Spec.idf",
        "Baseline_GlzSys6_13" => "../../../lib/resources/GlzSys_16095-air-3000_Spec.idf",
        "GlzSys_6_withoutPV" => "../../../lib/resources/GlzSys_10-air-9_Spec.idf",
        "GlzSys_13_withoutPV" => "../../../lib/resources/GlzSys_11F-air-3000_Spec.idf",
        "GlzSys_6_withPV" => "../../../lib/resources/GlzSys19_13F-air-9_Spec.idf",
        "GlzSys_13_withPV" => "../../../lib/resources/GlzSys20_14F-air-3000_Spec.idf",
        "GlzSys_Dark" => "../../../lib/resources/GlzSys_Dark_PV_Spec.idf",
        "GlzSys_Light" => "../../../lib/resources/GlzSys_Light_PV_Spec.idf",
        "GlzSys_Thermochromic_40C" => "../../../lib/resources/GlzSys_Thermochromic_40C.idf",
        "GlzSys_Thermochromic_35C" => "../../../lib/resources/GlzSys_Thermochromic_35C.idf",
        "GlzSys_Thermochromic_30C" => "../../../lib/resources/GlzSys_Thermochromic_30C.idf",
        "FrameTest_wFrame" => "../../../lib/resources/Window_PV_frame_Spec.idf",
        "FrameTest_woFrame" => "../../../lib/resources/Window_PV_No_frame_Spec_Spec.idf",
        "VeryHot_ASHRAE" => "../../../lib/resources/ASHRAE_zone12_Spec.idf",
        "Hot_ASHRAE" => "../../../lib/resources/ASHRAE_zone3_Spec.idf",
        "Cold_ASHRAE" => "../../../lib/resources/ASHRAE_zone456_Spec.idf",
        "VeryCold_ASHRAE" => "../../../lib/resources/ASHRAE_zone78_Spec.idf", 
        "VeryHot_SwitchGlaze" => "../../../lib/resources/SG_zone12_Spec.idf",
        "Hot_SwitchGlaze" => "../../../lib/resources/SG_zone3_Spec.idf",
        "Cold_SwitchGlaze" => "../../../lib/resources/SG_zone456_Spec.idf",
        "VeryCold_SwitchGlaze" => "../../../lib/resources/SG_zone78_Spec.idf",
        "VeryHot_Dark" => "../../../lib/resources/dark_zone12_Spec.idf",
        "VeryHot_Light" => "../../../lib/resources/light_zone12_Spec.idf",
        "Hot_Dark" => "../../../lib/resources/dark_zone3_Spec.idf",
        "Hot_Light" => "../../../lib/resources/light_zone3_Spec.idf", 
        "Cold_Dark" => "../../../lib/resources/dark_zone456_Spec.idf",
        "Cold_Light" => "../../../lib/resources/light_zone456_Spec.idf",
        "VeryCold_Dark" => "../../../lib/resources/dark_zone78_Spec.idf",
        "VeryCold_Light" => "../../../lib/resources/light_zone78_Spec.idf", 
      } 
    elsif serverrun == false
      runner.registerInfo("Reading idf files from the local #{idf_path} directory")
      dictionary = {
        "Baseline_GlzSys6" => "#{idf_path}/GlzSys_16095-air-9_Spec.idf",
        "Baseline_GlzSys13" => "#{idf_path}/GlzSys_6374-air-3000_Spec.idf",
        "Baseline_GlzSys15" => "#{idf_path}/GlzSys_10F-air-3000_Spec.idf",
        "Baseline_GlzSys15_withPV" => "#{idf_path}/GlzSys21_13F-air-3000_Spec.idf",
        "Baseline_GlzSys6_13" => "#{idf_path}/GlzSys_16095-air-3000_Spec.idf",
        "GlzSys_6_withoutPV" => "#{idf_path}/GlzSys_10-air-9_Spec.idf",
        "GlzSys_13_withoutPV" => "#{idf_path}/GlzSys_11F-air-3000_Spec.idf",
        "GlzSys_6_withPV" => "#{idf_path}/GlzSys19_13F-air-9_Spec.idf",
        "GlzSys_13_withPV" => "#{idf_path}/GlzSys20_14F-air-3000_Spec.idf",
        "GlzSys_Dark" => "#{idf_path}/GlzSys_Dark_PV_Spec.idf",
        "GlzSys_Light" => "#{idf_path}/GlzSys_Light_PV_Spec.idf",
        "GlzSys_Thermochromic_40C" => "#{idf_path}/GlzSys_Thermochromic_40C.idf",
        "GlzSys_Thermochromic_35C" => "#{idf_path}/GlzSys_Thermochromic_35C.idf",
        "GlzSys_Thermochromic_30C" => "#{idf_path}/GlzSys_Thermochromic_30C.idf",
        "FrameTest_wFrame" => "#{idf_path}/Window_PV_frame_Spec.idf",
        "FrameTest_woFrame" => "#{idf_path}/Window_PV_No_frame_Spec_Spec.idf",
        "VeryHot_ASHRAE" => "#{idf_path}/ASHRAE_zone12_Spec.idf",
        "Hot_ASHRAE" => "#{idf_path}/ASHRAE_zone3_Spec.idf",
        "Cold_ASHRAE" => "#{idf_path}/ASHRAE_zone456_Spec.idf",
        "VeryCold_ASHRAE" => "#{idf_path}/ASHRAE_zone78_Spec.idf", 
        "VeryHot_SwitchGlaze" => "#{idf_path}/SG_zone12_Spec.idf",
        "Hot_SwitchGlaze" => "#{idf_path}/SG_zone3_Spec.idf",
        "Cold_SwitchGlaze" => "#{idf_path}/SG_zone456_Spec.idf",
        "VeryCold_SwitchGlaze" => "#{idf_path}/SG_zone78_Spec.idf",
        "VeryHot_Dark" => "#{idf_path}/dark_zone12_Spec.idf",
        "VeryHot_Light" => "#{idf_path}/light_zone12_Spec.idf",
        "Hot_Dark" => "#{idf_path}/dark_zone3_Spec.idf",
        "Hot_Light" => "#{idf_path}/light_zone3_Spec.idf", 
        "Cold_Dark" => "#{idf_path}/dark_zone456_Spec.idf",
        "Cold_Light" => "#{idf_path}/light_zone456_Spec.idf",
        "VeryCold_Dark" => "#{idf_path}/dark_zone78_Spec.idf",
        "VeryCold_Light" => "#{idf_path}/light_zone78_Spec.idf",      
      } 
    end
    ####################################################################################
    ####################################################################################
      

    # report initial condition
    runner.registerInitialCondition("The initial IDF file had #{workspace.objects.size} objects.")

    # load IDF
    runner.registerInfo("Reading window idf from: #{dictionary[glztype]}")
    source_idf = OpenStudio::IdfFile::load(OpenStudio::Path.new(dictionary[glztype])).get

    # add everything from the file
    workspace.addObjects(source_idf.objects)    

    runner.registerInitialCondition("Imposing fenestration construction name change on #{choice}.")
 
    ####################################################################################
    #find the fenestration surface to change
    ####################################################################################
    no_found = true
    applicable = true
    fenestrationsurfaces = workspace.getObjectsByType("FenestrationSurface:Detailed".to_IddObjectType)
    fenestrationsurfaces.each do |fenestrationsurface|
      if fenestrationsurface.getString(0).to_s.eql?(choice) || choice.eql?($allchoices)
        no_found = false
        if applicable  #skip the modeling procedure if the model is not supported
          runner.registerInfo("Changing [#{fenestrationsurface.getString(2)}] to [#{glztype}]")
          fenestrationsurface.setString(2,glztype)
          
          #fenestrationsurface.setString(6,"ASHRAE_zone78-Frame") #TODO: change this more interactively/automatically
          
        end
      end
    end
    
    ####################################################################################
    #find the thermochromic object and replace switching temperature based on input
    ####################################################################################
    if thermochromicwindow==true 
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