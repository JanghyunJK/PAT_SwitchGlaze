require 'openstudio-standards'
require "openstudio/extension/core/os_lib_schedules.rb"
require "openstudio/extension/core/os_lib_helper_methods"


class AddThermochromicBIPV < OpenStudio::Measure::ModelMeasure

  # human-readable name
  def name
    return "Add Thermochromic BIPV"
  end

  # summary description
  def description
    return "Adds BIPV (Building Integrated Photovoltaic) on window surfaces. Define switching temperature for thermochromic windows. Implement power conversion efficiency difference between light and dark state windows."
  end

  # description of modeling approach
  def modeler_description
    return "Adds simple PV object for BIPV implementation. Implement thermochromic window with switching temperature definition. Implement power conversion efficiency difference betwee light and dark state windows."
  end

  # define the user arguments
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # facades to receive BIPV
    choices = OpenStudio::StringVector.new
    choices << "Tnt_50%_S_I0"
    choices << "Tnt_50%_S_I0pt4"
    choices << "Tnt_50%_S_I0pt6"
    choices << "Tnt_50%_S_I0pt8"
    choices << "Tnt_50%_N_I0"
    choices << "Tnt_50%_N_I0pt4"
    choices << "Tnt_50%_N_I0pt6"
    choices << "Tnt_50%_N_I0pt8"
    choices << "Tnt_25%_N_I0"
    choices << "Tnt_25%_N_I0pt4"
    choices << "Tnt_25%_N_I0pt6"
    choices << "Tnt_25%_N_I0pt8"
    choices << "Tnt_20%_N_I0"
    choices << "Tnt_20%_N_I0pt4"
    choices << "Tnt_20%_N_I0pt6"
    choices << "Tnt_20%_N_I0pt8"
    choices << "Tnt_15%_N_I0"
    choices << "Tnt_15%_N_I0pt4"
    choices << "Tnt_15%_N_I0pt6"
    choices << "Tnt_15%_N_I0pt8"
    choices << "Tnt_10%_N_I0"
    choices << "Tnt_10%_N_I0pt4"
    choices << "Tnt_10%_N_I0pt6"
    choices << "Tnt_10%_N_I0pt8"
    choices << "Tnt_5%_N_I0"
    choices << "Tnt_5%_N_I0pt4"
    choices << "Tnt_5%_N_I0pt6"
    choices << "Tnt_5%_N_I0pt8"
    choices << "Tnt_0pt5%_N_I0"
    choices << "Tnt_0pt5%_N_I0pt4"
    choices << "Tnt_0pt5%_N_I0pt6"
    choices << "Tnt_0pt5%_N_I0pt8"
    choices << "Tr_0pt5%_N_I0"
    choices << "Tr_0pt5%_N_I0pt4"
    choices << "Tr_0pt5%_N_I0pt6"
    choices << "Tr_0pt5%_N_I0pt8"
    choices << "Tr_5%_N_I0"
    choices << "Tr_5%_N_I0pt4"
    choices << "Tr_5%_N_I0pt6"
    choices << "Tr_5%_N_I0pt8"
    choices << "V_0pt5%_N_I0"
    choices << "V_0pt5%_N_I0pt4"
    choices << "V_0pt5%_N_I0pt6"
    choices << "V_0pt5%_N_I0pt8"
    choices << "V_5%_N_I0"
    choices << "V_5%_N_I0pt4"
    choices << "V_5%_N_I0pt6"
    choices << "V_5%_N_I0pt8"
    choices << "Tr_25%_N_I0"
    choices << "Tr_25%_N_I0pt4"
    choices << "Tr_25%_N_I0pt6"
    choices << "Tr_25%_N_I0pt8"
    choices << "Tr_50%_N_I0"
    choices << "Tr_50%_N_I0pt4"
    choices << "Tr_50%_N_I0pt6"
    choices << "Tr_50%_N_I0pt8"
    choices << "Tr_50%_S_I0"
    choices << "Tr_50%_S_I0pt4"
    choices << "Tr_50%_S_I0pt6"
    choices << "Tr_50%_S_I0pt8"
    choices << "V_25%_N_I0"
    choices << "V_25%_N_I0pt4"
    choices << "V_25%_N_I0pt6"
    choices << "V_25%_N_I0pt8"
    choices << "V_50%_N_I0"
    choices << "V_50%_N_I0pt4"
    choices << "V_50%_N_I0pt6"
    choices << "V_50%_N_I0pt8"
    choices << "V_50%_S_I0"
    choices << "V_50%_S_I0pt4"
    choices << "V_50%_S_I0pt6"
    choices << "V_50%_S_I0pt8"
    
    iqe = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("iqe", choices)
    iqe.setDisplayName("iqe")
    iqe.setDefaultValue("25%_N_I0")
    args << iqe

    # facades to receive BIPV
    choices = OpenStudio::StringVector.new
    choices << "N"
    choices << "E"
    choices << "S"
    choices << "W"
    choices << "ESW"  
    choices << "ALL"
    choices << "NONE" # for baseline
    facade = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("facade", choices)
    facade.setDisplayName("facade")
    facade.setDefaultValue("S")
    args << facade

    # thermochromic window implementation 
    pce_scenarios = OpenStudio::StringVector.new
    pce_scenarios << "Static"
    pce_scenarios << "SwitchGlaze"    
    pce_scenario = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('pce_scenario', pce_scenarios, true)
    pce_scenario.setDisplayName("Choice of power conversion efficiency modeling scenario")
    pce_scenario.setDefaultValue("Static")
    args << pce_scenario

    # PV surface QD coverage (%)
    dot_coverage = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("dot_coverage", true)
    dot_coverage.setDisplayName("Active portion of PV from window surface area")
    dot_coverage.setUnits("fraction")
    dot_coverage.setDefaultValue(1.0)
    args << dot_coverage

    # using IQE
    use_tint_iqe = OpenStudio::Ruleset::OSArgument::makeBoolArgument('use_tint_iqe', false)
    use_tint_iqe.setDisplayName('Dynamic power conversion efficiency?')
    use_tint_iqe.setDefaultValue('false')
    use_tint_iqe.setDescription('select true if selection of window will be based on tinted level and IQE setting (associated PCE value will be automatically applied)')
    args << use_tint_iqe
    
    # pv module efficiency (%)
    pv_eff = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("pv_eff", true)
    pv_eff.setDisplayName("Fixed PV power conversion efficiency")
    pv_eff.setDescription('this value is applied if dynamic power conversion efficiency is false.')
    pv_eff.setUnits("fraction")
    pv_eff.setDefaultValue(1.0)
    args << pv_eff

    inverter_eff = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("inverter_eff", true)
    inverter_eff.setDisplayName("Fixed Inverter Efficiency")
    inverter_eff.setUnits("fraction")
    inverter_eff.setDefaultValue(1.0)
    args << inverter_eff    
    
    # pv module efficiency (%)
    pv_eff_light = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("pv_eff_light", true)
    pv_eff_light.setDisplayName("PV power conversion efficiency in light state")
    pv_eff_light.setDescription('this value is applied if dynamic power conversion efficiency is false.')
    pv_eff_light.setUnits("fraction")
    pv_eff_light.setDefaultValue(0.0053)
    args << pv_eff_light
    
    # pv module efficiency (%)
    pv_eff_dark = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("pv_eff_dark", true)
    pv_eff_dark.setDisplayName("PV power conversion efficiency in dark state")
    pv_eff_dark.setDescription('this value is applied if dynamic power conversion efficiency is false.')
    pv_eff_dark.setUnits("fraction")
    pv_eff_dark.setDefaultValue(0.18)
    args << pv_eff_dark
    
    # thermochromic switching temperature
    switch_t = OpenStudio::Ruleset::OSArgument.makeDoubleArgument('switch_t', true)
    switch_t.setDisplayName('State switching temperature for thermochromic window')
    switch_t.setDescription('this value is applied if switchglaze is selected.')
    switch_t.setUnits("C")
    switch_t.setDefaultValue(30.0)
    args << switch_t

    debug_mode = OpenStudio::Ruleset::OSArgument::makeBoolArgument('debug_mode', false)
    debug_mode.setDisplayName('Debug Mode')
    debug_mode.setDefaultValue('false')
    debug_mode.setDescription('Print debugging info')
    args << debug_mode

    return args
  end

  def log_info(str)
    @runner.registerInfo(str)
  end

  # optional outputs to be displayed in PAT 
  def outputs 
    result = OpenStudio::Measure::OSOutputVector.new
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_rated_output') # w/m^2
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('panel_rated_output_ip') # w/ft^2
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('system_rated_output') # w
    result << OpenStudio::Measure::OSOutput.makeDoubleOutput('pv_area_total_ip') # w\ft^2
    result << OpenStudio::Measure::OSOutput.makeStringOutput('facade') # w\ft^2
    return result
  end

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    ##########################################################################

    # assign the user inputs to variables
    dot_coverage = runner.getDoubleArgumentValue('dot_coverage',user_arguments)
    pv_eff = runner.getDoubleArgumentValue('pv_eff',user_arguments)
    inverter_eff = runner.getDoubleArgumentValue('inverter_eff',user_arguments)
    panel_rated_output = (dot_coverage * pv_eff) * 1000 #w/m^2 (basis 50w/m^2, 0.05 eff, 0.50 coverage (5% conversion, 1Kw/m^2))
    facade = runner.getStringArgumentValue('facade',user_arguments)
    debug_mode = runner.getStringArgumentValue('debug_mode',user_arguments)
    use_tint_iqe = runner.getStringArgumentValue('use_tint_iqe',user_arguments)
    iqe = runner.getStringArgumentValue('iqe',user_arguments)
    pce_scenario = runner.getStringArgumentValue('pce_scenario',user_arguments)
    pv_eff_light = runner.getDoubleArgumentValue('pv_eff_light',user_arguments)
    pv_eff_dark = runner.getDoubleArgumentValue('pv_eff_dark',user_arguments)
    switch_t = runner.getDoubleArgumentValue('switch_t', user_arguments)
    
    ##########################################################################
    # dictionary for IQE and PCE connection
    ##########################################################################
    
    dictionary_iqe_pce = Hash.new
    dictionary_iqe_pce = {
      # 50% VLT
      "Tnt_50%_S_I0" => [0,0,0],
      "Tnt_50%_S_I0pt4" => [0.063462,0.062819,0.13557],
      "Tnt_50%_S_I0pt6" => [0.095248,0.094249,0.13539],
      "Tnt_50%_S_I0pt8" => [0.127,0.12567,0.13539],
      "Tnt_50%_N_I0" => [0,0,0],
      "Tnt_50%_N_I0pt4" => [0.052395,0.051907,0.10806],
      "Tnt_50%_N_I0pt6" => [0.078593,0.07786,0.10806],
      "Tnt_50%_N_I0pt8" => [0.10479,0.10382,0.10805],
      # 25% VLT
      "Tnt_25%_N_I0" => [0,0,0],
      "Tnt_25%_N_I0pt4" => [0.06382,0.063153,0.12693],
      "Tnt_25%_N_I0pt6" => [0.09572,0.094725,0.12696],
      "Tnt_25%_N_I0pt8" => [0.12764,0.12631,0.12693],
      "Tnt_25%_N_I0_Dark" => [0,0,0],
      "Tnt_25%_N_I0pt4_Dark" => [0.06382,0.063153,0.12693],
      "Tnt_25%_N_I0pt6_Dark" => [0.09572,0.094725,0.12696],
      "Tnt_25%_N_I0pt8_Dark" => [0.12764,0.12631,0.12693],
      "Tnt_25%_N_I0_Light" => [0,0,0],
      "Tnt_25%_N_I0pt4_Light" => [0.0016858,0.001608,0.084473],
      "Tnt_25%_N_I0pt6_Light" => [0.0025286,0.0024119,0.084463],
      "Tnt_25%_N_I0pt8_Light" => [0.0033715,0.0032158,0.084456],
      # 20% VLT
      "Tnt_20%_N_I0_Dark" => [0,0,0],
      "Tnt_20%_N_I0pt4_Dark" => [0.0698,0.069,0.121],
      "Tnt_20%_N_I0pt6_Dark" => [0.105,0.103,0.121],
      "Tnt_20%_N_I0pt8_Dark" => [0.139,0.138,0.121],
      "Tnt_20%_N_I0_Light" => [0,0,0],
      "Tnt_20%_N_I0pt4_Light" => [0.0016858,0.001608,0.084473],
      "Tnt_20%_N_I0pt6_Light" => [0.0025286,0.0024119,0.084463],
      "Tnt_20%_N_I0pt8_Light" => [0.0033715,0.0032158,0.084456],
      # 15% VLT
      "Tnt_15%_N_I0_Dark" => [0,0,0],
      "Tnt_15%_N_I0pt4_Dark" => [0.076,0.075,0.118],
      "Tnt_15%_N_I0pt6_Dark" => [0.113,0.113,0.118],
      "Tnt_15%_N_I0pt8_Dark" => [0.151,0.15,0.118],
      "Tnt_15%_N_I0_Light" => [0,0,0],
      "Tnt_15%_N_I0pt4_Light" => [0.0016858,0.001608,0.084473],
      "Tnt_15%_N_I0pt6_Light" => [0.0025286,0.0024119,0.084463],
      "Tnt_15%_N_I0pt8_Light" => [0.0033715,0.0032158,0.084456],
      # 10% VLT
      "Tnt_10%_N_I0_Dark" => [0,0,0],
      "Tnt_10%_N_I0pt4_Dark" => [0.082,0.082,0.115],
      "Tnt_10%_N_I0pt6_Dark" => [0.123,0.123,0.115],
      "Tnt_10%_N_I0pt8_Dark" => [0.165,0.163,0.115],
      "Tnt_10%_N_I0_Light" => [0,0,0],
      "Tnt_10%_N_I0pt4_Light" => [0.0016858,0.001608,0.084473],
      "Tnt_10%_N_I0pt6_Light" => [0.0025286,0.0024119,0.084463],
      "Tnt_10%_N_I0pt8_Light" => [0.0033715,0.0032158,0.084456],
      # 5% VLT
      "Tnt_5%_N_I0_Dark" => [0,0,0],
      "Tnt_5%_N_I0pt4_Dark" => [0.090521,0.089666,0.10816],
      "Tnt_5%_N_I0pt6_Dark" => [0.13578,0.1345,0.10816],
      "Tnt_5%_N_I0pt8_Dark" => [0.18094,0.17925,0.10828],
      "Tnt_5%_N_I0_Light" => [0,0,0],
      "Tnt_5%_N_I0pt4_Light" => [0.0016858,0.001608,0.084473],
      "Tnt_5%_N_I0pt6_Light" => [0.0025286,0.0024119,0.084463],
      "Tnt_5%_N_I0pt8_Light" => [0.0033715,0.0032158,0.084456],
      # 0.5% VLT
      "Tnt_0pt5%_N_I0_Dark" => [0,0,0],
      "Tnt_0pt5%_N_I0pt4_Dark" => [0.1015,0.10032,0.10089],
      "Tnt_0pt5%_N_I0pt6_Dark" => [0.15226,0.15048,0.10089],
      "Tnt_0pt5%_N_I0pt8_Dark" => [0.20301,0.20064,0.10089],
      "Tnt_0pt5%_N_I0_Light" => [0,0,0],
      "Tnt_0pt5%_N_I0pt4_Light" => [0.0023416,0.0022699,0.092563],
      "Tnt_0pt5%_N_I0pt6_Light" => [0.0035124,0.0034048,0.092562],
      "Tnt_0pt5%_N_I0pt8_Light" => [0.0046832,0.0045397,0.092561],
      # Triple 5% VLT
      "Tr_5%_N_I0_Dark" => [0,0,0],
      "Tr_5%_N_I0pt4_Dark" => [0.090521,0.089666,0.10816],
      "Tr_5%_N_I0pt6_Dark" => [0.13578,0.1345,0.10816],
      "Tr_5%_N_I0pt8_Dark" => [0.18094,0.17925,0.10828],
      "Tr_5%_N_I0_Light" => [0,0,0],
      "Tr_5%_N_I0pt4_Light" => [0.0016858,0.001608,0.084473],
      "Tr_5%_N_I0pt6_Light" => [0.0025286,0.0024119,0.084463],
      "Tr_5%_N_I0pt8_Light" => [0.0033715,0.0032158,0.084456],
      # Triple 0.5% VLT
      "Tr_0pt5%_N_I0_Dark" => [0,0,0],
      "Tr_0pt5%_N_I0pt4_Dark" => [0.1015,0.10032,0.10089],
      "Tr_0pt5%_N_I0pt6_Dark" => [0.15226,0.15048,0.10089],
      "Tr_0pt5%_N_I0pt8_Dark" => [0.20301,0.20064,0.10089],
      "Tr_0pt5%_N_I0_Light" => [0,0,0],
      "Tr_0pt5%_N_I0pt4_Light" => [0.0023416,0.0022699,0.092563],
      "Tr_0pt5%_N_I0pt6_Light" => [0.0035124,0.0034048,0.092562],
      "Tr_0pt5%_N_I0pt8_Light" => [0.0046832,0.0045397,0.092561],
      # VIG 5% VLT
      "V_5%_N_I0_Dark" => [0,0,0],
      "V_5%_N_I0pt4_Dark" => [0.090521,0.089666,0.10816],
      "V_5%_N_I0pt6_Dark" => [0.13578,0.1345,0.10816],
      "V_5%_N_I0pt8_Dark" => [0.18094,0.17925,0.10828],
      "V_5%_N_I0_Light" => [0,0,0],
      "V_5%_N_I0pt4_Light" => [0.0016858,0.001608,0.084473],
      "V_5%_N_I0pt6_Light" => [0.0025286,0.0024119,0.084463],
      "V_5%_N_I0pt8_Light" => [0.0033715,0.0032158,0.084456],
      # VIG 0.5% VLT
      "V_0pt5%_N_I0_Dark" => [0,0,0],
      "V_0pt5%_N_I0pt4_Dark" => [0.1015,0.10032,0.10089],
      "V_0pt5%_N_I0pt6_Dark" => [0.15226,0.15048,0.10089],
      "V_0pt5%_N_I0pt8_Dark" => [0.20301,0.20064,0.10089],
      "V_0pt5%_N_I0_Light" => [0,0,0],
      "V_0pt5%_N_I0pt4_Light" => [0.0023416,0.0022699,0.092563],
      "V_0pt5%_N_I0pt6_Light" => [0.0035124,0.0034048,0.092562],
      "V_0pt5%_N_I0pt8_Light" => [0.0046832,0.0045397,0.092561],
      # Triple 50% VLT
      "Tr_50%_S_I0" => [0,0,0],
      "Tr_50%_S_I0pt4" => [0.063462,0.062819,0.13557],
      "Tr_50%_S_I0pt6" => [0.095248,0.094249,0.13539],
      "Tr_50%_S_I0pt8" => [0.127,0.12567,0.13539],
      "Tr_50%_N_I0" => [0,0,0],
      "Tr_50%_N_I0pt4" => [0.052395,0.051907,0.10806],
      "Tr_50%_N_I0pt6" => [0.078593,0.07786,0.10806],
      "Tr_50%_N_I0pt8" => [0.10479,0.10382,0.10805],
      # Triple 25% VLT
      "Tr_25%_N_I0" => [0,0,0],
      "Tr_25%_N_I0pt4" => [0.06382,0.063153,0.12693],
      "Tr_25%_N_I0pt6" => [0.09572,0.094725,0.12696],
      "Tr_25%_N_I0pt8" => [0.12764,0.12631,0.12693],
      # VIG 50% VLT
      "V_50%_S_I0" => [0,0,0],
      "V_50%_S_I0pt4" => [0.063462,0.062819,0.13557],
      "V_50%_S_I0pt6" => [0.095248,0.094249,0.13539],
      "V_50%_S_I0pt8" => [0.127,0.12567,0.13539],
      "V_50%_N_I0" => [0,0,0],
      "V_50%_N_I0pt4" => [0.052395,0.051907,0.10806],
      "V_50%_N_I0pt6" => [0.078593,0.07786,0.10806],
      "V_50%_N_I0pt8" => [0.10479,0.10382,0.10805],
      # VIG 25% VLT
      "V_25%_N_I0" => [0,0,0],
      "V_25%_N_I0pt4" => [0.06382,0.063153,0.12693],
      "V_25%_N_I0pt6" => [0.09572,0.094725,0.12696],
      "V_25%_N_I0pt8" => [0.12764,0.12631,0.12693],
    }
      
    ##########################################################################
    
    if facade == "NONE"
      return false
    end

	  target_transmittance = 1.0
    inputs = {
        'name' => "PV Shading Transmittance Schedule",
        'winterTimeValuePairs' => { 24.0 => target_transmittance },
        'summerTimeValuePairs' => { 24.0 => target_transmittance },
        'defaultTimeValuePairs' => { 24.0 => target_transmittance }
    }
    shading_surface_transmittance_schedule = OsLib_Schedules.createSimpleSchedule(model,inputs)

    # get the windows
    ext_windows = []
    ext_windows_name = []
    model.getSubSurfaces.each do |s|
      ext_windows << s if s.subSurfaceType == "FixedWindow" && s.outsideBoundaryCondition == "Outdoors"
    end

    # report initial condition
    runner.registerInitialCondition("Input building contains #{ext_windows.size.to_s} exterior windows")

    # get user selection set
    candidate_windows = []
    if facade == "NONE"
      # base case, do nothing.
    else
      ext_windows.each do |s|
        azimuth = OpenStudio::Quantity.new(s.azimuth,OpenStudio::createSIAngle)
        azimuth = OpenStudio::convert(azimuth,OpenStudio::createIPAngle).get.value
        if facade == "ALL"
          candidate_windows << s
          ext_windows_name << s.name.to_s
          next
        end
        candidate_windows << s if (azimuth >= 315.0 or azimuth < 45.0) && facade == 'N'
        candidate_windows << s if (azimuth >= 45.0 and azimuth < 135.0) && facade == 'E'
        candidate_windows << s if (azimuth >= 135.0 and azimuth < 225.0) && facade == 'S'
        candidate_windows << s if (azimuth >= 225.0 and azimuth < 315.0) && facade == 'W'
        candidate_windows << s if (azimuth >= 45.0 and azimuth < 315.0) && facade == 'ESW'
        ext_windows_name << s.name.to_s if (azimuth >= 315.0 or azimuth < 45.0) && facade == 'N'
        ext_windows_name << s.name.to_s if (azimuth >= 45.0 and azimuth < 135.0) && facade == 'E'
        ext_windows_name << s.name.to_s if (azimuth >= 135.0 and azimuth < 225.0) && facade == 'S'
        ext_windows_name << s.name.to_s if (azimuth >= 225.0 and azimuth < 315.0) && facade == 'W'
        ext_windows_name << s.name.to_s if (azimuth >= 45.0 and azimuth < 315.0) && facade == 'ESW'
      end
    end
    runner.registerInfo("#{candidate_windows.size.to_s} windows meet facade selection criteria (facade = '#{facade}')")
    runner.registerInfo("Surface names affected = #{ext_windows_name}")

    # create the inverter
    inverter = OpenStudio::Model::ElectricLoadCenterInverterSimple.new(model)
    inverter.setInverterEfficiency(inverter_eff)
    runner.registerInfo("Created inverter with efficiency of #{inverter.inverterEfficiency}")

    # create the distribution system
    elcd = OpenStudio::Model::ElectricLoadCenterDistribution.new(model)
    elcd.setInverter(inverter)
    elcd.setName('UbiQD - Distribution')

    pv_area_total = 0.0
    system_rated_output = 0.0

    candidate_windows.each do |surface|

      # make single shading surface group for each window
      shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
      # set the space on the shading group
      shading_surface_group.setSpace(surface.space.get) if surface.space.is_initialized

      vec = surface.outwardNormal
      vec = vec
      vec.setLength(0.0254) # PV surface projection in meters

      # get window points and project along window normal
      vertices = surface.vertices

      transform = OpenStudio::Transformation.new
      transform = surface.space.get.transformation if surface.space.is_initialized

      # transform to world coords
      vertices = transform * vertices

      points = []
      vertices.each do |f|
        if debug_mode
          runner.registerInfo("window vertex: #{f}, projected PV vertex: #{f + vec}")
        end
        pp = f + vec
        points << pp
      end

      points = transform.inverse * points # send back to space coords

      # PV surface
      shading_surface = OpenStudio::Model::ShadingSurface.new(points, model)
      pv_area = OpenStudio::getArea(shading_surface.vertices()).get
      pv_area_total += pv_area
      pv_area_ip = OpenStudio.convert(pv_area, "m^2", "ft^2")
      shading_surface.setShadingSurfaceGroup(shading_surface_group)
      shading_surface.setName("PV - #{surface.name}")
      shading_surface.setTransmittanceSchedule(shading_surface_transmittance_schedule)
      panel = OpenStudio::Model::GeneratorPhotovoltaic::simple(model)
      panel.setSurface(shading_surface)

      runner.registerInfo("added PV panel area: #{pv_area.round(2)} m^2 (#{pv_area_ip} ft^2)") if debug_mode
	    panel_output = panel_rated_output * pv_area
	    runner.registerInfo("added PV panel output: #{panel_output.round(1)} W (#{pv_area} m^2)") if debug_mode

	    panel.setRatedElectricPowerOutput(panel_output)
	  
      simplepv = panel.photovoltaicPerformance.to_PhotovoltaicPerformanceSimple.get
      simplepv.setFractionOfSurfaceAreaWithActiveSolarCells(dot_coverage)
      
      ######################################################
      ######################################################            
      if (pce_scenario == "SwitchGlaze") && (use_tint_iqe == "false") && (facade != "NONE")
      
        surfacename = surface.name.to_s
        surfacename_strip = surfacename.gsub(/\s+/, "")
      
        pce_sch = OpenStudio::Model::ScheduleConstant.new(model)
        pce_sch.setName("PCE_SCH_#{surfacename_strip}")
        pce_sch.setValue(0.05)
        runner.registerInfo("Created new Schedule:Constant object (#{pce_sch.name}) representing constant power conversion efficiency.") 
    
        simplepv.setEfficiencySchedule(pce_sch)
    
        runner.registerInfo("Simple PV object name = #{simplepv.name}")
        runner.registerInfo("Associated surface name = #{surfacename_strip}")
        runner.registerInfo("Associated schedule name = #{pce_sch.name}")
      
        # Create new EnergyManagementSystem:Sensor object
        temperature_reference = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Surface Window Thermochromic Layer Property Specification Temperature")
        temperature_reference.setName("t_#{surfacename_strip}")
        temperature_reference.setKeyName(surfacename.to_s)
        runner.registerInfo("EMS Sensor named #{temperature_reference.name} measuring the reference temperature on #{surfacename} added to the model.")
     
        # Create EMS Actuator Objects
        pce_sch_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(pce_sch,"Schedule:Constant","Schedule Value")
        pce_sch_actuator.setName("pce_sch_#{surfacename_strip}")
        runner.registerInfo("EMS Actuator object named '#{pce_sch_actuator.name}' representing the temporary schedule to #{surfacename} added to the model.") 
      
        # Create new EnergyManagementSystem:Program object
        ems_pce_prg = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
        ems_pce_prg.setName("program_pce_#{surfacename_strip}")
        ems_pce_prg.addLine("SET T_ref_#{surfacename_strip} = #{temperature_reference.name.to_s}")
        ems_pce_prg.addLine("IF (T_ref_#{surfacename_strip} < #{switch_t})")
        ems_pce_prg.addLine("SET #{pce_sch.name} = #{pv_eff_light}")
        ems_pce_prg.addLine("ELSEIF (T_ref_#{surfacename_strip} >= #{switch_t})") 
        ems_pce_prg.addLine("SET #{pce_sch.name} = #{pv_eff_dark}")
        ems_pce_prg.addLine("ENDIF") 
        runner.registerInfo("EMS Program object named '#{ems_pce_prg.name}' added to modify the PCE schedule on #{surfacename}.")
      
        # create new EnergyManagementSystem:ProgramCallingManager object 
        ems_prgm_calling_mngr = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
        ems_prgm_calling_mngr.setName("callingmanager_pce_#{surfacename_strip}")
        ems_prgm_calling_mngr.setCallingPoint("BeginTimestepBeforePredictor")
        ems_prgm_calling_mngr.addProgram(ems_pce_prg)
        runner.registerInfo("EMS Program Calling Manager object named '#{ems_prgm_calling_mngr.name}' added to call #{ems_pce_prg.name} EMS program.")
        
        runner.registerInfo("Power conversion efficiency of #{pv_eff_light} applied to #{simplepv.name.to_s} for light state")
        runner.registerInfo("Power conversion efficiency of #{pv_eff_dark} applied to #{simplepv.name.to_s} for dark state")
        
      elsif (pce_scenario == "SwitchGlaze") && (use_tint_iqe == "true") && (facade != "NONE")
      
        surfacename = surface.name.to_s
        surfacename_strip = surfacename.gsub(/\s+/, "")
      
        pce_sch = OpenStudio::Model::ScheduleConstant.new(model)
        pce_sch.setName("PCE_SCH_#{surfacename_strip}")
        pce_sch.setValue(0.05)
        runner.registerInfo("Created new Schedule:Constant object (#{pce_sch.name}) representing constant power conversion efficiency.") 
    
        simplepv.setEfficiencySchedule(pce_sch)
    
        runner.registerInfo("Simple PV object name = #{simplepv.name}")
        runner.registerInfo("Associated surface name = #{surfacename_strip}")
        runner.registerInfo("Associated schedule name = #{pce_sch.name}")
      
        # Create new EnergyManagementSystem:Sensor object
        temperature_reference = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Surface Window Thermochromic Layer Property Specification Temperature")
        temperature_reference.setName("t_#{surfacename_strip}")
        temperature_reference.setKeyName(surfacename.to_s)
        runner.registerInfo("EMS Sensor named #{temperature_reference.name} measuring the reference temperature on #{surfacename} added to the model.")
        
        incident_angle = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Surface Outside Face Beam Solar Incident Angle Cosine Value")
        incident_angle.setName("a_#{surfacename_strip}")
        incident_angle.setKeyName(surfacename.to_s)
        runner.registerInfo("EMS Sensor named #{incident_angle.name} measuring the solar incident angle on #{surfacename} added to the model.")
     
        # Create EMS Actuator Objects
        pce_sch_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(pce_sch,"Schedule:Constant","Schedule Value")
        pce_sch_actuator.setName("pce_sch_#{surfacename_strip}")
        runner.registerInfo("EMS Actuator object named '#{pce_sch_actuator.name}' representing the temporary schedule to #{surfacename} added to the model.")       
      
        # Create new EnergyManagementSystem:Program object 
        runner.registerInfo("EMS Program being created to simulate PCE variation for #{iqe}") 
        ems_pce_prg = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
        ems_pce_prg.setName("program_pce_#{surfacename_strip}")
        ems_pce_prg.addLine("SET a_deg_#{surfacename_strip} = (@ArcCos a_#{surfacename_strip})*180/PI")
        ems_pce_prg.addLine("SET T_ref_#{surfacename_strip} = #{temperature_reference.name.to_s}")
        ems_pce_prg.addLine("IF (T_ref_#{surfacename_strip} < #{switch_t})")
        ems_pce_prg.addLine("IF (a_deg_#{surfacename_strip} == 90)")
        ems_pce_prg.addLine("SET #{pce_sch.name} = 0")
        ems_pce_prg.addLine("ELSEIF (a_deg_#{surfacename_strip} > 90)")
        ems_pce_prg.addLine("SET #{pce_sch.name} = 0")
        ems_pce_prg.addLine("ELSE")
        ems_pce_prg.addLine("SET expterm_l_#{surfacename_strip} = #{dictionary_iqe_pce[iqe+"_Light"][2]}*(a_deg_#{surfacename_strip}-90)")
        ems_pce_prg.addLine("SET #{pce_sch.name} = #{dictionary_iqe_pce[iqe+"_Light"][0]}-#{dictionary_iqe_pce[iqe+"_Light"][1]}*(@EXP expterm_l_#{surfacename_strip})")
        ems_pce_prg.addLine("ENDIF")
        ems_pce_prg.addLine("ELSEIF (T_ref_#{surfacename_strip} >= #{switch_t})") 
        ems_pce_prg.addLine("IF (a_deg_#{surfacename_strip} == 90)")
        ems_pce_prg.addLine("SET #{pce_sch.name} = 0")
        ems_pce_prg.addLine("ELSEIF (a_deg_#{surfacename_strip} > 90)")
        ems_pce_prg.addLine("SET #{pce_sch.name} = 0")
        ems_pce_prg.addLine("ELSE")
        ems_pce_prg.addLine("SET expterm_d_#{surfacename_strip} = #{dictionary_iqe_pce[iqe+"_Dark"][2]}*(a_deg_#{surfacename_strip}-90)")
        ems_pce_prg.addLine("SET #{pce_sch.name} = #{dictionary_iqe_pce[iqe+"_Dark"][0]}-#{dictionary_iqe_pce[iqe+"_Dark"][1]}*(@EXP expterm_d_#{surfacename_strip})")
        ems_pce_prg.addLine("ENDIF")
        ems_pce_prg.addLine("ENDIF") 
        runner.registerInfo("EMS Program object named '#{ems_pce_prg.name}' added to modify the PCE schedule on #{surfacename}.")
      
        # create new EnergyManagementSystem:ProgramCallingManager object 
        ems_prgm_calling_mngr = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
        ems_prgm_calling_mngr.setName("callingmanager_pce_#{surfacename_strip}")
        ems_prgm_calling_mngr.setCallingPoint("BeginTimestepBeforePredictor")
        ems_prgm_calling_mngr.addProgram(ems_pce_prg)
        runner.registerInfo("EMS Program Calling Manager object named '#{ems_prgm_calling_mngr.name}' added to call #{ems_pce_prg.name} EMS program.") 
        
        ####################################################################################################################
        # Create new EnergyManagementSystem:GlobalVariable object 
        dynamic_pce = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "dynamic_pce_#{surfacename_strip}")
      
        # Create new EMS Output Variable Object
        ems_output_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model,dynamic_pce)
        ems_output_var.setName("dynamic_pce_#{surfacename_strip}")
        ems_output_var.setEMSVariableName("#{pce_sch.name}")
        ems_output_var.setTypeOfDataInVariable("Averaged")
        ems_output_var.setUpdateFrequency("SystemTimeStep")
        ####################################################################################################################
   
        runner.registerInfo("Power conversion efficiency coefficient set of #{dictionary_iqe_pce[iqe+"_Light"]} applied to #{simplepv.name.to_s} for light state")
        runner.registerInfo("Power conversion efficiency coefficient set of #{dictionary_iqe_pce[iqe+"_Dark"]} applied to #{simplepv.name.to_s} for dark state")
        
      elsif (pce_scenario == "Static") && (use_tint_iqe == "false") && (facade != "NONE")
      
        simplepv.setFixedEfficiency(pv_eff)
        runner.registerInfo("Constant power conversion efficiency of #{pv_eff} applied to #{simplepv.name.to_s}")
        
      elsif (pce_scenario == "SwitchGlaze") && (use_tint_iqe == "false") && (facade == "NONE")
      
        simplepv.setFixedEfficiency(dictionary_iqe_pce[iqe])
        runner.registerInfo("Constant power conversion efficiency of #{dictionary_iqe_pce[iqe]} applied to #{simplepv.name.to_s}")
        
      elsif (pce_scenario == "Static") && (use_tint_iqe == "true") && (facade != "NONE")
      
        surfacename = surface.name.to_s
        surfacename_strip = surfacename.gsub(/\s+/, "")
      
        pce_sch = OpenStudio::Model::ScheduleConstant.new(model)
        pce_sch.setName("PCE_SCH_#{surfacename_strip}")
        pce_sch.setValue(0.05)
        runner.registerInfo("Created new Schedule:Constant object (#{pce_sch.name}) representing constant power conversion efficiency.") 
    
        simplepv.setEfficiencySchedule(pce_sch)
    
        runner.registerInfo("Simple PV object name = #{simplepv.name}")
        runner.registerInfo("Associated surface name = #{surfacename_strip}")
        runner.registerInfo("Associated schedule name = #{pce_sch.name}")
      
        # Create new EnergyManagementSystem:Sensor object        
        incident_angle = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Surface Outside Face Beam Solar Incident Angle Cosine Value")
        incident_angle.setName("a_#{surfacename_strip}")
        incident_angle.setKeyName(surfacename.to_s)
        runner.registerInfo("EMS Sensor named #{incident_angle.name} measuring the solar incident angle on #{surfacename} added to the model.")
     
        # Create EMS Actuator Objects
        pce_sch_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(pce_sch,"Schedule:Constant","Schedule Value")
        pce_sch_actuator.setName("pce_sch_#{surfacename_strip}")
        runner.registerInfo("EMS Actuator object named '#{pce_sch_actuator.name}' representing the temporary schedule to #{surfacename} added to the model.")       
      
        # Create new EnergyManagementSystem:Program object
        runner.registerInfo("EMS Program being created to simulate PCE variation for #{iqe}")
        ems_pce_prg = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
        ems_pce_prg.setName("program_pce_#{surfacename_strip}")
        ems_pce_prg.addLine("SET a_deg_#{surfacename_strip} = (@ArcCos a_#{surfacename_strip})*180/PI")
        ems_pce_prg.addLine("IF (a_deg_#{surfacename_strip} == 90)")
        ems_pce_prg.addLine("SET #{pce_sch.name} = 0")
        ems_pce_prg.addLine("ELSEIF (a_deg_#{surfacename_strip} > 90)")
        ems_pce_prg.addLine("SET #{pce_sch.name} = 0")
        ems_pce_prg.addLine("ELSE")
        ems_pce_prg.addLine("SET expterm_l_#{surfacename_strip} = #{dictionary_iqe_pce[iqe][2]}*(a_deg_#{surfacename_strip}-90)")
        ems_pce_prg.addLine("SET #{pce_sch.name} = #{dictionary_iqe_pce[iqe][0]}-#{dictionary_iqe_pce[iqe][1]}*(@EXP expterm_l_#{surfacename_strip})")
        ems_pce_prg.addLine("ENDIF") 
        runner.registerInfo("EMS Program object named '#{ems_pce_prg.name}' added to modify the PCE schedule on #{surfacename}.")
      
        # create new EnergyManagementSystem:ProgramCallingManager object 
        ems_prgm_calling_mngr = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
        ems_prgm_calling_mngr.setName("callingmanager_pce_#{surfacename_strip}")
        ems_prgm_calling_mngr.setCallingPoint("BeginTimestepBeforePredictor")
        ems_prgm_calling_mngr.addProgram(ems_pce_prg)
        runner.registerInfo("EMS Program Calling Manager object named '#{ems_prgm_calling_mngr.name}' added to call #{ems_pce_prg.name} EMS program.") 
        
        ####################################################################################################################
        # Create new EnergyManagementSystem:GlobalVariable object 
        dynamic_pce = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "dynamic_pce_#{surfacename_strip}")
      
        # Create new EMS Output Variable Object
        ems_output_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model,dynamic_pce)
        ems_output_var.setName("dynamic_pce_#{surfacename_strip}")
        ems_output_var.setEMSVariableName("#{pce_sch.name}")
        ems_output_var.setTypeOfDataInVariable("Averaged")
        ems_output_var.setUpdateFrequency("SystemTimeStep")
        ####################################################################################################################
   
        runner.registerInfo("Power conversion efficiency coefficient set of #{dictionary_iqe_pce[iqe]} applied to #{simplepv.name.to_s}")
        
      end
      ######################################################
      ######################################################

      # connect panel to electric load center distribution
      elcd.addGenerator(panel)

     end

    # define outputs for server analyses

    # get num_stories_above_grade and story_multiplier from preceding measure
    # get multiplier method, expecting: ["Basements Ground Mid Top", "none"]
    story_multiplier = OsLib_HelperMethods.check_upstream_measure_for_arg(runner, 'story_multiplier')
    scaled_note = ""
    if story_multiplier[:value] == "Basements Ground Mid Top"
      scaled_note = '(scaled)'
      num_stories_above_grade = OsLib_HelperMethods.check_upstream_measure_for_arg(runner, 'num_stories_above_grade')
      pv_area_total_initial = pv_area_total
      pv_area_total = ((pv_area_total/3) * (num_stories_above_grade[:value].to_f - 2)) + ((pv_area_total/3) * 2)
      runner.registerWarning("Zone multipliers in use (story multiplier method = #{story_multiplier[:value]}).") if debug_mode
      runner.registerWarning("Scaling PV panel area to account for zone multipliers (initial: #{pv_area_total_initial}, scaled: #{pv_area_total}).") if debug_mode
    end

    # convert total to IP units
    # NOTE: OpenStudio.convert did *not* return a useable value for runner.registerValue. I tried.
    pv_area_total_ip = pv_area_total * 10.7639 # m^2 --> ft^2
    panel_rated_output_ip = panel_rated_output * 0.09290304 # w/m^2 --> w/ft^2

    system_rated_output = panel_rated_output * pv_area_total #w
    runner.registerValue("system_rated_output", system_rated_output.round(2))
    runner.registerInfo("Total system rated output is #{system_rated_output} watts, (panel: #{panel_rated_output_ip} w/ft^2 * panel area: #{pv_area_total_ip} ft^2)")
    runner.registerValue("panel_rated_output", panel_rated_output.round(2)) #w/m^2
    runner.registerValue("panel_rated_output_ip", panel_rated_output_ip.round(2)) #w/ft^2

    runner.registerValue("pv_area_total", pv_area_total.round(2)) #m^2
    runner.registerValue("pv_area_total_ip", pv_area_total_ip.round(2)) #ft^2

    runner.registerFinalCondition("#{model.getShadingSurfaces.size} PV surfaces (#{pv_area_total_ip.round(2)} ft^2 total area #{scaled_note}) added to model (facade = '#{facade}').")

    return true

  end

end

# register the measure to be used by the application
AddThermochromicBIPV.new.registerWithApplication
