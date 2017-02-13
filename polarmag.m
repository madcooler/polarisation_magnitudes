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

ArStokesVectorSample * sv_temp [ 8 ];

ArStokesVector * sv;

void getIntensity(
    ART_GV          * art_gv,
    ArStokesVector  * sv   ,
    double          * valueI
)
{
    
    for(int j =0; j < 8; j++)
    {
//        arstokesvectorsample_dddd_init_sv(art_gv, 0, 0, 0, 0, sv_temp[j]) ;
        
        arstokesvector_sv_sample_at_wavelength_svs(art_gv, sv, 380.0 NM + j * 40 NM, sv_temp[j]);

//        ArSpectralSample spectralSampleI = ARSTOKESVECTORSAMPLE_SV_I(*sv_temp[j], 0);
        
        valueI[j] = C1_C_PRINTF(SS_C(ARSTOKESVECTORSAMPLE_SV_I(*sv_temp[j], 0)));
        
//        valueI[j] = C1_C_PRINTF(SS_C(spectralSampleI));
    }
}

void readFile(
    ART_GV                  *  art_gv,
    ArnFileImage            *  inputFileImage,
//    ArnPlainImage           *  lightAlphaImage,
    ArnLightAlphaImage      *  lightAlphaLine,
//    IVec2D                     size,
    int                        xPos,
//    int                        yPos,
    double                  *  valueI
    )

{

    if ( [ inputFileImage dataImageClass ] == [ ArfARTRAW class ] )
    {
        
        arlightalpha_l_to_sv(art_gv, lightAlphaLine->data[ xPos ], sv);
        
        getIntensity(art_gv,sv,valueI);
        
        
//        [ ART_GLOBAL_REPORTER endAction ];
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
        "ART raw & colourspace image difference utility",
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
    
    ArnPlainImage  * lightAlphaImage_p =
            [ ALLOC_OBJECT(ArnLightAlphaImage)
                initWithSize
                :   size
                ];

    ArnLightAlphaImage  * lightAlphaLine_p =
            [ ALLOC_OBJECT(ArnLightAlphaImage)
                initWithSize
                :   IVEC2D(XC(size),1)
                ];

    
    double averageMag = 0;
    
    FILE * dataFile ;
    char dataFileName[50] = "";
        
    strcat(dataFileName,"diff_mag.txt");
    
    dataFile = fopen(dataFileName, "w");
    
    for(int j =0; j < 8; j++)
    {
        sv_temp[j] = arstokesvectorsample_alloc(art_gv);
    }
    
    sv = arstokesvector_alloc(art_gv);
    
    //    for(int k = 250 ; k < XC( size ); k = k + step)
//        for(int l = 250 ; l < XC( size ); l = l + step)
    
    [ inputFileImage getPlainImage
            :   IPNT2D( 0, 0 )
            :   lightAlphaImage
            ];
    
    [ inputFileImage_p getPlainImage
            :   IPNT2D( 0, 0 )
            :   lightAlphaImage_p
            ];
    double maxMagArray[xe-xs][ye-ys];
    double averageMagArray[xe-xs][ye-ys];
    
    double all_intensity_p;
    
    double all_intensity;
    
    for(int l = ys ; l < ye; l = l + step)
    {
        
        [ lightAlphaImage getPlainImage
            :   IPNT2D( 0, l )
            :   lightAlphaLine
            ];
        
        [ lightAlphaImage_p getPlainImage
            :   IPNT2D( 0, l )
            :   lightAlphaLine_p
            ];


        for( int k = xs; k < xe; k = k + step)
        {
            
            readFile(art_gv, inputFileImage,   lightAlphaLine,   k, data  );
            readFile(art_gv, inputFileImage_p, lightAlphaLine_p, k, data_p);

            averageMag = 0;
            maxMag     = 0;
            originMag  = 0;
            channel    = 0;
            
            all_intensity_p = 0;
            all_intensity   = 0;
            
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
                all_intensity  += data[i];
                all_intensity_p+= data_p[i];
            }
            
            averageMag = averageMag / 8;
            
            maxMagArray[k-xs][l-ys] = maxMag;
            averageMagArray[k-xs][l-ys]  = averageMag;
            
//            printf("%d %d %f %f \n",k, l,averageMag, maxMag);

            // print the columm, row number and difference magnitude.
            fprintf(dataFile,"%d %d %f %f %f %f %f %f %f %f %f %f %f %f %d\n",
                    k,
                    l,
                    averageMag,
                    maxMag,
                    all_intensity_p,
                    all_intensity,
                    data_p[7],data[7],
                    data_p[5],data[5],
                    data_p[3],data[3],
                    data_p[0],data[0],
                    channel );

        }
    }
    
//    
//    for(int k = xs; k < xe; k = k + step)
//        for(int l = ys ; l < ye; l = l + step)
//    {
//        fprintf(dataFile,"%d %d %f %f \n",k, l,averageMagArray[k-xs][l-ys], maxMagArray[k-xs][l-ys]);
//        //            fprintf(dataFile,"%d %d %f %f %f %d %f  %f \n",k, l,averageMag, maxMag, originMag, channel , data[channel], data_p[channel]);
//        
//    }
    
    
    
    fclose(dataFile);
    
    arstokesvector_free(art_gv, sv);

    RELEASE_OBJECT(lightAlphaLine);
    RELEASE_OBJECT(lightAlphaImage);

    return 0;

             
}

ADVANCED_RENDERING_TOOLKIT_MAIN(polarmag)
