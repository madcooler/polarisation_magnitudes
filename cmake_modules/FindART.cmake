# LuNo(6/1/2016): Short cmake script to find the Advanced Rendering Toolkit (ART)

find_path(
	art_include_dir
	NAME
	AdvancedRenderingToolkit.h
	PATHS
		/usr/local/lib/ART_Resources/arm2art/include
		/Library/ART_Resources/arm2art/include
		/lib/ART_Resources/arm2art/include
		~/Library/ART_Resources/arm2art/include
		~/lib/ART_Resources/arm2art/include
	)

find_library(
	art_framework
	NAME
		AdvancedRenderingToolkit
	PATHS
		/usr/local/Library/Frameworks/
		/Library/Frameworks/
		~/Library/Frameworks/
	CMAKE_FIND_FRAMEWORK
		ONLY)

IF (art_include_dir AND art_framework)
   set(art_found_true)
ENDIF (art_include_dir AND art_framework)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
   ART
   REQUIRED_VARS
	art_framework
	art_include_dir
   FAIL_MESSAGE
	"Could not find ART"
   )
