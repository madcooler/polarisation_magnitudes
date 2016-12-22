/*!
 
 @file      imp.m
 
 @brief     This file is the main ART file for the imp project.
 
 @author    Chi Wang (chi@cgg.mff.cuni.cz), Lukas Novosad (novosad@cgg.mff.cuni.cz)
 @date
 
 */
// ART library imports
#import "AdvancedRenderingToolkit.h"


// define some default values
#define     IMP_DEFAULT_INCIDENT_ANGLE          40 DEGREES
#define     IMP_DEFAULT_IMAGE_RESOLUTION        512
#define     IMP_DEFAULT_NUMBER_OF_SAMPLES       10000000

double data[8]  ={0,0,0,0,0,0,0,0};
double data_p[8]={0,0,0,0,0,0,0,0};

// maximum magnitude
double maxMag = 0;

// unsigned magnitude
double originMag = 0;

int    channel = -1;


void getIntensity(
    ART_GV          * art_gv,
    ArStokesVector  * sv   ,
    double          * valueI
)
{
    ArStokesVectorSample * sv_temp [ 8 ];

    for(int j =0; j < 8; j++)
    {
        sv_temp[j] = arstokesvectorsample_alloc(art_gv);
                
        arstokesvector_sv_sample_at_wavelength_svs(art_gv, sv, 380.0 NM + j * 40 NM, sv_temp[j]);

        ArSpectralSample spectralSampleI = ARSTOKESVECTORSAMPLE_SV_I(*sv_temp[j], 0);
        
        valueI[j] = C1_C_PRINTF(SS_C(spectralSampleI));
    }
}

void readFile(
    ART_GV                  *  art_gv,
    ArnFileImage            *  inputFileImage,
    ArnPlainImage           *  lightAlphaImage,
    ArnLightAlphaImage      *  lightAlphaLine,
    IVec2D                     size,
    int                        xPos,
    int                        yPos,
    double                  *  valueI
    )

{

if ( [ inputFileImage dataImageClass ] == [ ArfARTRAW class ] )
    {
//        ArfARTRAW  * rawImage =
//            (ArfARTRAW *) inputFileImage->imageFile;
//
//        ArSpectrumType  rawContentType = [ rawImage fileColourType ];
//
//        //   Check if the current ISR is already set to match the contents
//        //   of the RAW file
//
//        if ( rawContentType != art_isr( art_gv ) )
//        {
//            //   If they do not match...
//
//            [ ART_GLOBAL_REPORTER beginAction
//                :   "automatically switching ISR to match ARTRAW contents"
//                ];
//
//            char  * newInputFileName;
//
//            arstring_s_copy_s(
//                  [ inputFileImage fileName ],
//                & newInputFileName
//                );
//
//            [ ART_GLOBAL_REPORTER printf
//                :   "Default ISR was : %s\n"
//                ,   arspectrumtype_name( art_isr( art_gv ) )
//                ];
//
//            [ ART_GLOBAL_REPORTER printf
//                :   "ARTRAW content is : %s\n"
//                ,   arspectrumtype_name( rawContentType )
//                ];
//
//            if ( rawContentType == arspectrum_ciexyz )
//                rawContentType = arspectrum_ut_rgb;
//
//            if ( rawContentType == arspectrum_ciexyz_polarisable )
//                rawContentType = arspectrum_ut_rgb_polarisable;
//
//            [ ART_GLOBAL_REPORTER printf
//                :   "ISR will be set as: %s\n"
//                ,   arspectrumtype_name( rawContentType )
//                ];
//
//            art_set_isr( art_gv, rawContentType );
//
//            [ ART_GLOBAL_REPORTER printf
//                :   "ISR is now set to : %s\n"
//                ,   arspectrumtype_name( art_isr( art_gv ) )
//                ];
//
//            [ ART_GLOBAL_REPORTER printf
//                :   "Re-reading raw image...\n"
//                ];
//
//            inputFileImage =
//                [ FILE_IMAGE
//                    :   newInputFileName
//                    ];
//
//            FREE_ARRAY( newInputFileName );
//
//            [ ART_GLOBAL_REPORTER printf
//                :   "Done.\n"
//                ];
//
//            [ ART_GLOBAL_REPORTER endAction ];
//        }

        
        
        [ inputFileImage getPlainImage
            :   IPNT2D( 0, 0 )
            :   lightAlphaImage
            ];

        [ lightAlphaImage getPlainImage
            :   IPNT2D( 0, yPos )
            :   lightAlphaLine
            ];

//        [ ART_GLOBAL_REPORTER beginAction
//            :   "extracting pixel information at location ( %ld | %ld ):\n"
//            ,   xPos
//            ,   yPos
//            ];

        ArLightAlpha  * value =
            lightAlphaLine->data[ xPos ];

        
        ArStokesVector * sv = arstokesvector_alloc(art_gv);

        arlightalpha_l_to_sv(art_gv, value, sv);
        
        getIntensity(art_gv,sv,valueI);
        
        arstokesvector_free(art_gv, sv);
        
//        [ ART_GLOBAL_REPORTER endAction ];
    }
    else
    {
        ArnPlainImage  * ciexyzAlphaImage =
            [ ALLOC_OBJECT(ArnCIEXYZAImage)
                initWithSize
                :   size
                ];

        ArnCIEXYZAImage  * ciexyzAlphaLine =
            [ ALLOC_OBJECT(ArnCIEXYZAImage)
                initWithSize
                :   IVEC2D(XC(size),1)
                ];

        [ inputFileImage getPlainImage
            :   IPNT2D( 0, 0 )
            :   ciexyzAlphaImage
            ];

        [ ciexyzAlphaImage getPlainImage
            :   IPNT2D( 0, yPos )
            :   ciexyzAlphaLine
            ];

        [ ART_GLOBAL_REPORTER beginAction
            :   "pixel information at location ( %ld | %ld ):\n"
            ,   xPos
            ,   yPos
            ];

        ArCIEXYZA  * value =
            & ciexyzAlphaLine->data[ xPos ];

//        printf("\n");

        xyza_c_debugprintf(
            art_gv,
            value
            );
        
        ArCIELuv  luvValue;
        
        xyz_to_luv(art_gv, & ARCIEXYZA_C(*value), & luvValue);
        
        luv_c_debugprintf( art_gv, & luvValue );
        
        ArCIEXYZ  xyz;
        
        luv_to_xyz(art_gv, &luvValue, &xyz);

        printf(
            "CIE UCS u' v' ( %f | %f )\n",
            luv_u_prime_from_xyz( art_gv, & xyz ),
            luv_v_prime_from_xyz( art_gv, & xyz )
            );
        
        ArnCIEXYZAImage  * avgLine[11];

        //  3x3 average is only done if we are sufficiently far from the border
        
        if (    xPos > 0
             && yPos > 0
             && xPos < XC( size ) - 1
             && yPos < YC( size ) - 1 )
        {
            printf(
                "\n3x3 average around location ( %d | %d ):\n",
                xPos,
                yPos
                );

            avgLine[4] =
                [ ALLOC_OBJECT(ArnCIEXYZAImage)
                    initWithSize
                    :   IVEC2D(XC(size),1)
                    ];
            
            [ ciexyzAlphaImage getPlainImage
                :   IPNT2D( 0, yPos - 1 )
                :   avgLine[4]
                ];


            avgLine[5] = ciexyzAlphaLine;

            avgLine[6] =
                [ ALLOC_OBJECT(ArnCIEXYZAImage)
                    initWithSize
                    :   IVEC2D(XC(size),1)
                    ];

            [ ciexyzAlphaImage getPlainImage
                :   IPNT2D( 0, yPos + 1 )
                :   avgLine[6]
                ];
            
            ArCIEXYZA  avg = ARCIEXYZA(0.0, 0.0, 0.0, 0.0);

            
            for ( int x = -1; x < 2; x++)
            {
                for ( int y = 4; y < 7; y++)
                {
                    ArCIEXYZA  * avgValue =
                        & avgLine[y]->data[ xPos + x];
                    
                    ARCIEXYZA_X(avg) += ARCIEXYZA_X(*avgValue);
                    ARCIEXYZA_Y(avg) += ARCIEXYZA_Y(*avgValue);
                    ARCIEXYZA_Z(avg) += ARCIEXYZA_Z(*avgValue);
                    ARCIEXYZA_A(avg) += ARCIEXYZA_A(*avgValue);
                }
            }
            
            ARCIEXYZA_X(avg) /= 9.0;
            ARCIEXYZA_Y(avg) /= 9.0;
            ARCIEXYZA_Z(avg) /= 9.0;
            ARCIEXYZA_A(avg) /= 9.0;

            xyza_c_debugprintf(
                  art_gv,
                & avg
                );
            
            xyz_to_luv(art_gv, & ARCIEXYZA_C(avg), & luvValue);
            
            luv_c_debugprintf( art_gv, & luvValue );

            printf(
                "CIE UCS u' v' ( %f | %f )\n",
                luv_u_prime_from_xyz( art_gv, & ARCIEXYZA_C(avg) ),
                luv_v_prime_from_xyz( art_gv, & ARCIEXYZA_C(avg) )
                );

        }
        
        //  5x5 average is only done if we are sufficiently far from the border
        
        if (    xPos > 1
             && yPos > 1
             && xPos < XC( size ) - 2
             && yPos < YC( size ) - 2 )
        {
            printf(
                "\n5x5 average around location ( %d | %d ):\n",
                xPos,
                yPos
                );

            avgLine[3] =
                [ ALLOC_OBJECT(ArnCIEXYZAImage)
                    initWithSize
                    :   IVEC2D(XC(size),1)
                    ];
            
            [ ciexyzAlphaImage getPlainImage
                :   IPNT2D( 0, yPos - 2 )
                :   avgLine[3]
                ];

            avgLine[7] =
                [ ALLOC_OBJECT(ArnCIEXYZAImage)
                    initWithSize
                    :   IVEC2D(XC(size),1)
                    ];

            [ ciexyzAlphaImage getPlainImage
                :   IPNT2D( 0, yPos + 2 )
                :   avgLine[7]
                ];
            
            ArCIEXYZA  avg = ARCIEXYZA(0.0, 0.0, 0.0, 0.0);
            
            for ( int x = -2; x < 3; x++)
            {
                for ( int y = 3; y < 8; y++)
                {
                    ArCIEXYZA  * avgValue =
                        & avgLine[y]->data[ xPos + x];
                    
                    ARCIEXYZA_X(avg) += ARCIEXYZA_X(*avgValue);
                    ARCIEXYZA_Y(avg) += ARCIEXYZA_Y(*avgValue);
                    ARCIEXYZA_Z(avg) += ARCIEXYZA_Z(*avgValue);
                    ARCIEXYZA_A(avg) += ARCIEXYZA_A(*avgValue);
                }
            }
            
            ARCIEXYZA_X(avg) /= 25.0;
            ARCIEXYZA_Y(avg) /= 25.0;
            ARCIEXYZA_Z(avg) /= 25.0;
            ARCIEXYZA_A(avg) /= 25.0;

            xyza_c_debugprintf(
                  art_gv,
                & avg
                );
            
            xyz_to_luv(art_gv, & ARCIEXYZA_C(avg), & luvValue);
            
            luv_c_debugprintf( art_gv, & luvValue );

            printf(
                "CIE UCS u' v' ( %f | %f )\n",
                luv_u_prime_from_xyz( art_gv, & ARCIEXYZA_C(avg) ),
                luv_v_prime_from_xyz( art_gv, & ARCIEXYZA_C(avg) )
                );

        }
        //  11x11 average is only done if we are sufficiently far from the border
        
        if (    xPos > 4
             && yPos > 4
             && xPos < XC( size ) - 5
             && yPos < YC( size ) - 5 )
        {
            printf(
                "\n11x11 average around location ( %ld | %ld ):\n",
                xPos,
                yPos
                );

            avgLine[0] =
                [ ALLOC_OBJECT(ArnCIEXYZAImage)
                    initWithSize
                    :   IVEC2D(XC(size),1)
                    ];
            
            [ ciexyzAlphaImage getPlainImage
                :   IPNT2D( 0, yPos - 5 )
                :   avgLine[0]
                ];

            avgLine[1] =
                [ ALLOC_OBJECT(ArnCIEXYZAImage)
                    initWithSize
                    :   IVEC2D(XC(size),1)
                    ];
            
            [ ciexyzAlphaImage getPlainImage
                :   IPNT2D( 0, yPos - 4 )
                :   avgLine[1]
                ];

            avgLine[2] =
                [ ALLOC_OBJECT(ArnCIEXYZAImage)
                    initWithSize
                    :   IVEC2D(XC(size),1)
                    ];
            
            [ ciexyzAlphaImage getPlainImage
                :   IPNT2D( 0, yPos - 3 )
                :   avgLine[2]
                ];

            avgLine[8] =
                [ ALLOC_OBJECT(ArnCIEXYZAImage)
                    initWithSize
                    :   IVEC2D(XC(size),1)
                    ];

            [ ciexyzAlphaImage getPlainImage
                :   IPNT2D( 0, yPos + 3 )
                :   avgLine[8]
                ];
            
            avgLine[9] =
                [ ALLOC_OBJECT(ArnCIEXYZAImage)
                    initWithSize
                    :   IVEC2D(XC(size),1)
                    ];

            [ ciexyzAlphaImage getPlainImage
                :   IPNT2D( 0, yPos + 4 )
                :   avgLine[9]
                ];
            
            avgLine[10] =
                [ ALLOC_OBJECT(ArnCIEXYZAImage)
                    initWithSize
                    :   IVEC2D(XC(size),1)
                    ];

            [ ciexyzAlphaImage getPlainImage
                :   IPNT2D( 0, yPos + 5 )
                :   avgLine[10]
                ];
            
            ArCIEXYZA  avg = ARCIEXYZA(0.0, 0.0, 0.0, 0.0);
            
            for ( int x = -5; x < 6; x++)
            {
                for ( int y = 0; y < 11; y++)
                {
                    ArCIEXYZA  * avgValue =
                        & avgLine[y]->data[ xPos + x];
                    
                    ARCIEXYZA_X(avg) += ARCIEXYZA_X(*avgValue);
                    ARCIEXYZA_Y(avg) += ARCIEXYZA_Y(*avgValue);
                    ARCIEXYZA_Z(avg) += ARCIEXYZA_Z(*avgValue);
                    ARCIEXYZA_A(avg) += ARCIEXYZA_A(*avgValue);
                }
            }
            
            ARCIEXYZA_X(avg) /= 121.0;
            ARCIEXYZA_Y(avg) /= 121.0;
            ARCIEXYZA_Z(avg) /= 121.0;
            ARCIEXYZA_A(avg) /= 121.0;

            xyza_c_debugprintf(
                  art_gv,
                & avg
                );
            
            xyz_to_luv(art_gv, & ARCIEXYZA_C(avg), & luvValue);
            
            luv_c_debugprintf( art_gv, & luvValue );

            printf(
                "CIE UCS u' v' ( %f | %f )\n",
                luv_u_prime_from_xyz( art_gv, & ARCIEXYZA_C(avg) ),
                luv_v_prime_from_xyz( art_gv, & ARCIEXYZA_C(avg) )
                );

        }
        
        [ ART_GLOBAL_REPORTER endAction ];
    }
}


int polarmag(
        int        argc,
        char    ** argv,
        ART_GV   * art_gv
        )
{
    ART_APPLICATION_DEFINE_STANDARD_OPTIONS_WITH_FEATURES(
        "ART image probe",
        art_appfeatures_no_threading
        );

    ART_APPLICATION_MAIN_OPTIONS_FOLLOW

    id  xOpt =
        [ INTEGER_OPTION
            :   "x"
            :   "xs"
            :   "<x coord>"
            :   "x start pixel"
            ];
    
    id  xEndOpt =
        [ INTEGER_OPTION
            :   "xend"
            :   "xe"
            :   "<x coord>"
            :   "x end pixel"
            ];


    id  yOpt =
        [ INTEGER_OPTION
            :   "ystart"
            :   "ys"
            :   "<y coord>"
            :   "y start pixel"
            ];
    
    id  yEndOpt =
        [ INTEGER_OPTION
            :   "yend"
            :   "ye"
            :   "<y coord>"
            :   "x end pixel"
            ];

    
    id  stepOpt =
        [ INTEGER_OPTION
            :   "step"
            :   "s"
            :   "<step>"
            :   "sampling step"
            ];


    ART_SINGLE_INPUT_FILE_APPLICATION_STARTUP(
        "polarisation_difference_imageprobe",
        "ART raw & colourspace image probe utility",
        "polarmag <ART image(Polarised)> <ART image> -xs <x start coord> -xe <x end coord> -ys <y startcoord> -ye <y end coord> -s <sampling step>"
        );

    if ( ! ( [ xOpt hasBeenSpecified ] && [ yOpt hasBeenSpecified ] ) )
    {
        ART_ERRORHANDLING_FATAL_ERROR("missing (x|y) probe coordinates");
    }
    
    const char  * inputFileName_p   = argv[1];
    const char  * inputFileName     = argv[2];
    

    ArnFileImage  * inputFileImage =
        [ FILE_IMAGE
            :   inputFileName
            ];
    ArnFileImage  * inputFileImage_p =
        [ FILE_IMAGE
            :   inputFileName_p
            ];

    IVec2D size = [ inputFileImage size ];
    
    [ ART_GLOBAL_REPORTER beginTimedAction
        :   "reading ART input image %s of size %d x %d"
        ,   inputFileImage_p
        ,   XC( size )
        ,   YC( size )
        ];


    [ ART_GLOBAL_REPORTER beginTimedAction
        :   "reading ART input image %s of size %d x %d"
        ,   inputFileName
        ,   XC( size )
        ,   YC( size )
        ];

    [ ART_GLOBAL_REPORTER endAction ];

    if ( ! (   ( [ inputFileImage dataImageClass ] == [ ArfARTRAW class ] )
            || ( [ inputFileImage dataImageClass ] == [ ArfARTCSP class ] )) )
        ART_ERRORHANDLING_FATAL_ERROR(
            "file is not an internal ART image file - "
            "%s instead of ArfARTRAW/CSP"
            ,   [ [ inputFileImage dataImageClass ] cStringClassName ]
            );
    
    int xs = [xOpt integerValue];
    int xe = [xEndOpt integerValue];
    
    int ys = [yOpt integerValue];
    int ye = [yEndOpt integerValue];

    
    int step = [stepOpt integerValue];
    
    ArnPlainImage  * lightAlphaImage =
            [ ALLOC_OBJECT(ArnLightAlphaImage)
                initWithSize
                :   size
                ];

    ArnLightAlphaImage  * lightAlphaLine =
            [ ALLOC_OBJECT(ArnLightAlphaImage)
                initWithSize
                :   IVEC2D(XC(size),1)
                ];
    
    double averageMag = 0;
    
    FILE * dataFile ;
    char dataFileName[50] = "";
        
    strcat(dataFileName,"diff_mag.txt");
    
    dataFile = fopen(dataFileName, "w");
    
    
    
    for(int k = xs; k < xe; k = k + step)
        for(int l = ys ; l < ye; l = l + step)
    
//    for(int k = 250 ; k < XC( size ); k = k + step)
//        for(int l = 250 ; l < XC( size ); l = l + step)
        {
            
            readFile(art_gv, inputFileImage,   lightAlphaImage, lightAlphaLine, size,  k,   l , data  );
            readFile(art_gv, inputFileImage_p, lightAlphaImage, lightAlphaLine, size,  k,   l , data_p);

            averageMag = 0;
            maxMag     = 0;
            originMag  = 0;
            channel    = 0;
            
            double magnitude[8];
            for (int i = 0; i < 8; i++)
            {
                magnitude[i] = (data_p[i] - data[i])/ data[i];
                
                if(data[i]!=0)
                {
                    averageMag += fabs(magnitude[i]);
                }
                if (maxMag<fabs(magnitude[i]))
                {
                    maxMag      = fabs(magnitude[i]);
                    originMag   = (magnitude[i]);
                    channel     = i;
                }
                
            }
            
            averageMag = averageMag / 8;
            fprintf(dataFile,"%d %d %f %f %f %d %f  %f \n",k, l,averageMag, maxMag, originMag, channel , data[channel], data_p[channel]);
            
        }
    
    fclose(dataFile);
    
    
    RELEASE_OBJECT(lightAlphaLine);
    RELEASE_OBJECT(lightAlphaImage);

    return 0;

             
}

ADVANCED_RENDERING_TOOLKIT_MAIN(polarmag)
