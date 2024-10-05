texture tex0 < string name = "Base.tga"; >;	// Base texture
texture tex1 < string name = "Base.tga"; >;	// Base texture
texture tex2 < string name = "Base.tga"; >;	// Base texture
texture tex3 < string name = "Base.tga"; >;	// Base texture
texture tex4 < string name = "Base.tga"; >;	// Base texture
texture tex5 < string name = "Base.tga"; >;	// fow

float4x4 WorldViewProjectionMatrix; 
float4x4 WorldMatrix;
float4x4 ViewProjectionMatrix;
float3	LightPosition;
float3	CameraPosition;
float	Time;
float	vAlpha;
float MaxSearchDistance = 25.0;
float DarkeningDistance = 2.0;


#define FOW_SIZE_X 1024;
#define FOW_SIZE_Y 512;
#define MAX_SEARCH_DISTANCE 25.0
#define DARKENING_DISTANCE 15.0
const float WATER_RATION = 0.5;
const float MAIN_TILING_FACTOR = 0.25;
const float FADE_DISTANCE = 100;

sampler BaseTexture  =
sampler_state
{
    Texture = <tex0>;
    MinFilter = Linear; //Point;
    MagFilter = Point;
    MipFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};



sampler TheBackgroundTexture  =
sampler_state
{
    Texture = <tex1>;
    MinFilter = Linear; //Point;
    MagFilter = Point;
    MipFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};


sampler TerraIncognitaFiltered  =
sampler_state
{
    Texture = <tex2>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU = Mirror;
    AddressV = Mirror;
};

sampler WorldColor  =
sampler_state
{
    Texture = <tex3>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler NormalMap  =
sampler_state
{
    Texture = <tex4>;
    MinFilter = Linear; //Point;
    MagFilter = Point;
    MipFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler Overlay  =
sampler_state
{
    Texture = <tex4>;
    MinFilter = Linear; //Point;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};

///

sampler WaterNormalMap  =
sampler_state
{
    Texture = <tex0>;
    MinFilter = Linear; //Point;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
//    AddressW = Wrap;
};

sampler FOWTexture  =
sampler_state
{
    Texture = <tex5>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU = Wrap;
    AddressV = Wrap;
};

///

struct VS_INPUT_WATER
{
    float3 position			: POSITION;
    float2 texCoord0			: TEXCOORD0;
    float2 texCoord1			: TEXCOORD1;
    float2 texCoord2			: TEXCOORD2;
};

struct VS_OUTPUT_WATER
{
    float4 position		: POSITION;
    float2 texCoord0		: TEXCOORD0;

    float3 eyeDirection		: TEXCOORD1;
    float3 lightDirection	: TEXCOORD2;
    float3 halfAngleDirection	: TEXCOORD3;
    float2 WorldTexture		: TEXCOORD4;
    float2 WorldTextureTI : TEXCOORD5;
    float2 texCoord1		: TEXCOORD6;
	float  heightFactor			: TEXCOORD7;
};


const float3 offY = float3(0.11, 0.74, 0.43);
const float3 offZ = float3(0.47, 0.19, 0.78);

////////////////////////////////////////////////////////////////////////////////////////////////////////////

#define X_OFFSET 0.5
#define Z_OFFSET 0.5

float	ColorMapHeight;
float	ColorMapWidth;

float	ColorMapTextureHeight;
float	ColorMapTextureWidth;

float	MapWidth;
float	MapHeight;

float	BorderWidth;
float	BorderHeight;

//#define BlendOverlayf(base, blend) 	(base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend)))
//#define BlendOverlay(base, blend) 		Blend(base, blend, BlendOverlayf)


VS_OUTPUT_WATER VertexShader_Water_2_0(const VS_INPUT_WATER IN )
{
	// Translate
	VS_OUTPUT_WATER OUT = (VS_OUTPUT_WATER)0;
	//float4 position = mul( float4(IN.position.xyz , 1.0) , WorldViewProjectionMatrix );
	float4 position = mul( float4(IN.position , 1.0), WorldViewProjectionMatrix );
	
	OUT.position = position;

	OUT.WorldTexture = IN.texCoord2;
	//OUT.WorldTexture.xy = float2( ( WorldPositionX + X_OFFSET)/ColorMapTextureWidth, (WorldPositionY + Z_OFFSET)/ColorMapTextureHeight );
	OUT.WorldTextureTI = IN.texCoord2;	//= float2( ( IN.texCoord1.x + 0.25)/BorderWidth, (IN.texCoord1.y + 0.25)/BorderHeight );
		
  	float4 tangent = float4(1.0, 0.0, 0.0, 0.0);
	float4 normal = float4(0.0, 1.0, 0.0, 0.0);
	float4 biTangent = float4(0.0, 0.0, 1.0, 0.0);
    
	OUT.texCoord0 = IN.texCoord0 + Time*0.02;

	float4 viewDir = float4( CameraPosition, 1 ) - position;
	OUT.eyeDirection.x = dot( viewDir, tangent );
	OUT.eyeDirection.y = dot( viewDir, normal );
	OUT.eyeDirection.z = dot( viewDir, biTangent );
//	OUT.eyeDirection.w = 1;

	
	float4 lightDir;
	lightDir.xyz = CameraPosition - LightPosition;
//	lightDir.w = 1;
	OUT.lightDirection.x = dot( viewDir, tangent );
	OUT.lightDirection.y = dot( viewDir, normal );
	OUT.lightDirection.z = dot( viewDir, biTangent );
//	OUT.lightDirection.w = 1;




   // Eye-linear texgen
   OUT.halfAngleDirection.x = 0.5 * (position.z + position.x);
   OUT.halfAngleDirection.y = 0.5 * (position.z - position.y);
   OUT.halfAngleDirection.z = position.z;
   // Object-linear texgen
//   OUT.texCoord0 = 0.5 + 0.01 * position.xyzw;
   
   
   return OUT;
}


float4 PixelShader_Water_2_0( VS_OUTPUT_WATER IN ) : COLOR
{
    // Sample the world color
    float4 WorldColorColor = tex2D(WorldColor, IN.WorldTexture);

    // Define land color
    float3 LandColor = float3(107.0/255.0, 123.0/255.0, 140.0/255.0);

    // Calculate color difference
    float3 ColorDiff = abs(WorldColorColor.rgb - LandColor);
    float ColorDistance = dot(ColorDiff, float3(1, 1, 1));

    // Debug visualization
    float4 DebugColor;

    // If color is close to land color, show as red; otherwise, show as blue
    if (ColorDistance < 0.3) // Adjust this threshold as needed
    {
        DebugColor = float4(1, 0, 0, 1); // Red for land
    }
    else
    {
        DebugColor = float4(0, 0, 1, 1); // Blue for water
    }

    //Visualize the color distance
    //DebugColor.rgb = float3(ColorDistance, ColorDistance, ColorDistance);

    // Use the debug color instead of the normal water color
    return DebugColor;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////

VS_OUTPUT_WATER VertexShader_Water_1_1(const VS_INPUT_WATER IN )
{
    VS_OUTPUT_WATER OUT = (VS_OUTPUT_WATER)0;
    float4 position = mul( float4(IN.position.xyz , 1.0) , WorldViewProjectionMatrix );
    OUT.position = position;
    OUT.texCoord0 = IN.texCoord0 + Time*0.1;
    
    float WorldPositionX = (ColorMapWidth * IN.texCoord1.x) / MapWidth;
	float WorldPositionY = (ColorMapHeight * IN.texCoord1.y) / MapHeight;
    OUT.WorldTexture.xy = float2( ( WorldPositionX + X_OFFSET)/ColorMapTextureWidth, (WorldPositionY + Z_OFFSET)/ColorMapTextureHeight );
    OUT.WorldTextureTI	= float2( ( IN.texCoord1.x + 0.25)/BorderWidth, (IN.texCoord1.y + 0.25)/BorderHeight );


	float3x3 objToTangentSpace;
	objToTangentSpace[0] = float3( 1, 0, 0 );
	objToTangentSpace[1] = float3( 0, 0, 1 );
	objToTangentSpace[2] = float3( 0, 1, 0 );

	float3 lightDir = normalize( LightPosition - CameraPosition );
	float3 viewDir = normalize( CameraPosition - IN.position.xyz );
    float3 halfAngleVector = normalize(lightDir + viewDir);

    OUT.lightDirection = normalize(mul(objToTangentSpace, lightDir.xyz)) * 0.5 + 0.5.xxx;
    OUT.halfAngleDirection = normalize(mul(objToTangentSpace, halfAngleVector.xyz)) * 0.5 + 0.5.xxx;

    return OUT;
}

float4 PixelShader_Water_1_1( VS_OUTPUT_WATER IN ) : COLOR
{
	float4 OutColor = float4( 0.3, 0.3, 0.7, 1 );
	
	float4 TerraIncognita = tex2D( TerraIncognitaFiltered, IN.WorldTextureTI );
	OutColor.rgba += ( TerraIncognita.g - 0.25 )*1.33;

	return OutColor;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
VS_OUTPUT_WATER VertexShader_HoiWater_2_0(const VS_INPUT_WATER IN )
{
	VS_OUTPUT_WATER OUT = (VS_OUTPUT_WATER)0;
	float4 position = mul( float4(IN.position , 1.0), WorldViewProjectionMatrix );
	OUT.position = position;

	OUT.WorldTexture = IN.texCoord2;
	OUT.texCoord1 = IN.texCoord1;
	
  	float4 tangent = float4(1.0, 0.0, 0.0, 0.0);
	float4 normal = float4(0.0, 1.0, 0.0, 0.0);
	float4 biTangent = float4(0.0, 0.0, 1.0, 0.0);
    
	OUT.texCoord0 = IN.texCoord0 * MAIN_TILING_FACTOR + Time*0.002;

	float4 viewDir = float4(0.0, 1.0, 1.0, 0.0);
	OUT.eyeDirection.x = dot( viewDir, tangent );
	OUT.eyeDirection.y = dot( viewDir, normal );
	OUT.eyeDirection.z = dot( viewDir, biTangent );

	float4 lightDir;
	lightDir.xyz = float4(0.0, 0.5, 1.0, 0.0);
	OUT.lightDirection.x = dot( viewDir, tangent );
	OUT.lightDirection.y = dot( viewDir, normal );
	OUT.lightDirection.z = dot( viewDir, biTangent );

	OUT.WorldTextureTI.x = IN.texCoord2.x * 1.0 / (ColorMapWidth / ColorMapTextureWidth);
	OUT.WorldTextureTI.x += 0.5 / FOW_SIZE_X;
	OUT.WorldTextureTI.y = IN.texCoord2.y * 1.0 / (ColorMapHeight / ColorMapTextureHeight);
	
	OUT.heightFactor = 0.0;//clamp(CameraPosition.y / FADE_DISTANCE, 0.0, 1.0);
	
	return OUT;
}

float Fresnel(float NdotL, float fresnelBias, float fresnelPow)

{
  float facing = (1.0 - NdotL);
  return max(fresnelBias +
             (1.0 - fresnelBias) * pow(facing, fresnelPow), 0.0);
}

const float WRAP = 0.8;
const float WaveModOne = 3.0;
const float WaveModTwo =  4.0;

const float SpecValueOne = 8.0;
const float SpecValueTwo =  2.0;

const float vWaterTransparens = 0.7; //more transparance lets you see more of background
const float vColorMapFactor = 2.5f; //how much colormap

float4 PixelShader_HoiWater_2_0( VS_OUTPUT_WATER IN ) : COLOR
{

	float2 coordA = IN.texCoord0.xy * 3;
	coordA.xy += 0.1;
	float2 coordB = IN.texCoord0.xy;
	coordB.y += 0.1;
	float2 coordC = IN.texCoord0.xy * 2;
	coordC.y += 0.15;
	float2 coordD = IN.texCoord0.xy * 5;
	coordD.y += 0.3;	
		
	float3 vBumpA = tex2D( WaterNormalMap, coordA.xy );
	coordB.x += 0.03 * Time;
	coordB.y -= 0.02 * Time;	
	float3 vBumpB = tex2D( WaterNormalMap, coordB.xy );
	coordC.x += 0.03 * Time;
	coordC.y -= 0.01 * Time;
	float3 vBumpC = tex2D( WaterNormalMap, coordC.xy );
	coordD.x += 0.02 * Time;
	coordD.y -= 0.01 * Time;
	float3 vBumpD = tex2D( WaterNormalMap, coordD.xy );

	float3 vBumpTex = normalize(WaveModOne * (vBumpA.xyz + vBumpB.xyz +
                                 vBumpC.xyz + vBumpD.xyz) - WaveModTwo);

	                                         	
	float3 WorldColorColor = tex2D( WorldColor, IN.WorldTexture );

	float3 eyeDir = normalize(IN.eyeDirection); 
	float NdotL = max(dot(eyeDir, (vBumpTex/2)), 0);
	
	NdotL = saturate((NdotL + WRAP) / (1 + WRAP));
	NdotL = lerp(NdotL, 1.0, IN.heightFactor);

	float3 OutColor = NdotL * (WorldColorColor * vColorMapFactor);
	
	float3	reflVector = -reflect( IN.lightDirection, vBumpTex );
	float	specular = dot( normalize( reflVector), eyeDir );	 
	specular = clamp( specular, 0.0, 1.0 );
	
	specular = pow( specular, SpecValueOne );
	specular = lerp(specular, 0.0, IN.heightFactor);
	OutColor += (specular/SpecValueTwo);

	float xoffset = 0.5 / FOW_SIZE_X;
	float yoffset = 0.5 / FOW_SIZE_Y;
	float FOW  = tex2D( FOWTexture, IN.WorldTextureTI + float2( -xoffset, yoffset) ).b;
	FOW  += tex2D( FOWTexture, IN.WorldTextureTI + float2( xoffset, yoffset) ).b;
	FOW  += tex2D( FOWTexture, IN.WorldTextureTI + float2( -xoffset, -yoffset) ).b;
	FOW  += tex2D( FOWTexture, IN.WorldTextureTI + float2( xoffset, -yoffset) ).b;
	
	FOW = saturate ( FOW / 2 - 1 ); // /2 because we do /4 then * 2
	FOW = saturate ( FOW + 0.5 );
	
	return float4( OutColor * FOW, vWaterTransparens);
}


////////////////
technique WaterShader_2_0
{
	pass p0
	{
		ALPHABLENDENABLE = True;

		VertexShader = compile vs_2_0 VertexShader_Water_2_0();
		PixelShader = compile ps_2_0 PixelShader_Water_2_0();
	}
}

technique WaterShader_1_1
{
	pass p0
	{
		ALPHABLENDENABLE = True;

		VertexShader = compile vs_1_1 VertexShader_Water_1_1();
		PixelShader = compile ps_2_0 PixelShader_Water_1_1();
	}
}

technique HoiWaterShader_2_0
{
	pass p0
	{
		ALPHATESTENABLE = True;
		ALPHABLENDENABLE = True;

		VertexShader = compile vs_2_0 VertexShader_HoiWater_2_0();
		PixelShader = compile ps_2_0 PixelShader_HoiWater_2_0();
	}
}


//// Watershader Far

struct VS_INPUT_WATER_FAR
{
    float4 position_uv		: POSITION;
};

struct VS_OUTPUT_WATER_FAR
{
    float4 position			: POSITION;
	float2 vWorldPos		: TEXCOORD0;
	float2 vUV				: TEXCOORD1;
};


VS_OUTPUT_WATER_FAR VertexShader_Far(const VS_INPUT_WATER_FAR IN )
{
	VS_OUTPUT_WATER_FAR OUT = (VS_OUTPUT_WATER_FAR)0;
	float2 pos = IN.position_uv.xy;
	pos -= CameraPosition.xz;
	OUT.position = mul( float4(pos.x, 0.2, pos.y, 1.0), ViewProjectionMatrix );
	OUT.vWorldPos = float2(IN.position_uv.x / 512.0, IN.position_uv.y / 512.0);
	OUT.vUV = IN.position_uv.zw;
	
	return OUT;
}

float4 PixelShader_Far(VS_OUTPUT_WATER_FAR IN) : COLOR
{
    float2 texSize = float2(ColorMapTextureWidth, ColorMapTextureHeight);
    float2 texelSize = 1.0 / texSize;

    float3 parchmentColor = float3(0.95, 0.93, 0.85); // 0.95, 0.93, 0.85
    float3 deepWaterColor = float3(0, 0, 0);  // This is actualy coastal water 232.0 / 255.0, 224.0 / 255.0, 184.0 / 255.0,  232.0 / 255.0, 224.0 / 255.0, 184.0 / 255.0

    float4 baseColor = tex2D(WorldColor, IN.vUV);

    float3 landColor = float3(107.0 / 255.0, 123.0 / 255.0, 140.0 / 255.0);
    float3 colorDiff = abs(baseColor.rgb - landColor);
    bool isLand = length(colorDiff) < 0.1;

    float coastalFactor = 0; // 0
    int sampleCount = 0;
    int sampleRadius = 8; // Reduced sampling radius from 12

    for (int x = -sampleRadius; x <= sampleRadius; x++) {
        for (int y = -sampleRadius; y <= sampleRadius; y++) {
            float2 offset = float2(texelSize.x * x, texelSize.y * y);
            float2 clampedUV = clamp(IN.vUV + offset, 0.0, 1.0);	// UV represents cutoff 
            float3 sampleColor = tex2D(WorldColor, clampedUV).rgb;
            colorDiff = abs(sampleColor - landColor);
            if (length(colorDiff) < 0.1) {
                coastalFactor += 1.0;
            }
            sampleCount++;
        }
    }

    coastalFactor = saturate(coastalFactor / sampleCount);

    float distanceFactor = saturate(length(IN.vWorldPos.xy) / 16000.0); // 16000
    coastalFactor = lerp(coastalFactor, 0.0, distanceFactor);
	
    float grayBaseColor = dot(baseColor.rgb, float3(0.299, 0.587, 0.114));

    // Apply contrast adjustment
    grayBaseColor = saturate(((grayBaseColor - 0.5) * 1.5) + 0.5);  // contrast 1.5

    // Interpolate between low and high colors based on the adjusted grayscale value
    float3 newWaterColor = lerp(baseColor.rgb, parchmentColor, grayBaseColor);

    //float3 newWaterColor = lerp(baseColor.rgb, parchmentColor, 0.5);
    float3 waterColor = lerp(newWaterColor.rgb, deepWaterColor, coastalFactor);

    float3 finalColor = isLand ? deepWaterColor : waterColor;

    //finalColor *= 1.05;

    return float4(finalColor, 1.0);
}

technique WaterShaderFar
{
	pass p0
	{
		ALPHATESTENABLE = False;
		ALPHABLENDENABLE = False;

		VertexShader = compile vs_3_0 VertexShader_Far();
		PixelShader = compile ps_3_0 PixelShader_Far();
	}
}
