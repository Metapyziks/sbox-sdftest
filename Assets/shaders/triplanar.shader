
HEADER
{
	Description = "";
}

FEATURES
{
	#include "common/features.hlsl"
}

MODES
{
	VrForward();
	Depth(); 
	ToolsVis( S_MODE_TOOLS_VIS );
	ToolsWireframe( "vr_tools_wireframe.shader" );
	ToolsShadingComplexity( "tools_shading_complexity.shader" );
}

COMMON
{
	#ifndef S_ALPHA_TEST
	#define S_ALPHA_TEST 1
	#endif
	#ifndef S_TRANSLUCENT
	#define S_TRANSLUCENT 0
	#endif
	
	#include "common/shared.hlsl"
	#include "procedural.hlsl"

	#define S_UV2 1
	#define CUSTOM_MATERIAL_INPUTS
}

struct VertexInput
{
	#include "common/vertexinput.hlsl"
	float4 vColor : COLOR0 < Semantic( Color ); >;
};

struct PixelInput
{
	#include "common/pixelinput.hlsl"
	float3 vPositionOs : TEXCOORD14;
	float3 vNormalOs : TEXCOORD15;
	float4 vTangentUOs_flTangentVSign : TANGENT	< Semantic( TangentU_SignV ); >;
	float4 vColor : COLOR0;
	float4 vTintColor : COLOR1;
};

VS
{
	#include "common/vertex.hlsl"

	PixelInput MainVs( VertexInput v )
	{
		PixelInput i = ProcessVertex( v );
		i.vPositionOs = v.vPositionOs.xyz;
		i.vColor = v.vColor;

		ExtraShaderData_t extraShaderData = GetExtraPerInstanceShaderData( v );
		i.vTintColor = extraShaderData.vTint;

		VS_DecodeObjectSpaceNormalAndTangent( v, i.vNormalOs, i.vTangentUOs_flTangentVSign );

		return FinalizeVertex( i );
	}
}

PS
{
	#include "common/pixel.hlsl"
	
	SamplerState g_sSampler0 < Filter( ANISO ); AddressU( WRAP ); AddressV( WRAP ); >;
	CreateInputTexture2D( Texture_ps_0, Srgb, 8, "None", "_color", ",0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	Texture2D g_tTexture_ps_0 < Channel( RGBA, Box( Texture_ps_0 ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	float3 g_v_SdfCursorPosition < Attribute( "_SdfCursorPosition" ); Default3( 0,0,0 ); >;
	float g_fl_SdfCursorRadius < Attribute( "_SdfCursorRadius" ); Default1( 128 ); >;
	float4 g_v_SdfCursorColor < Attribute( "_SdfCursorColor" ); Default4( 1.00, 1.00, 1.00, 1.00 ); >;
		
	float4 TexTriplanar_Color( in Texture2D tTex, in SamplerState sSampler, float3 vPosition, float3 vNormal )
	{
		float2 uvX = vPosition.zy;
		float2 uvY = vPosition.xz;
		float2 uvZ = vPosition.xy;
	
		float3 triblend = saturate(pow(abs(vNormal), 4));
		triblend /= max(dot(triblend, half3(1,1,1)), 0.0001);
	
		half3 axisSign = vNormal < 0 ? -1 : 1;
	
		uvX.x *= axisSign.x;
		uvY.x *= axisSign.y;
		uvZ.x *= -axisSign.z;
	
		float4 colX = Tex2DS( tTex, sSampler, uvX );
		float4 colY = Tex2DS( tTex, sSampler, uvY );
		float4 colZ = Tex2DS( tTex, sSampler, uvZ );
	
		return colX * triblend.x + colY * triblend.y + colZ * triblend.z;
	}
	
	float4 MainPs( PixelInput i ) : SV_Target0
	{
		Material m = Material::Init();
		m.Albedo = float3( 1, 1, 1 );
		m.Normal = float3( 0, 0, 1 );
		m.Roughness = 1;
		m.Metalness = 0;
		m.AmbientOcclusion = 1;
		m.TintMask = 1;
		m.Opacity = 1;
		m.Emission = float3( 0, 0, 0 );
		m.Transmission = 0;
		
		float4 l_0 = i.vTintColor;
		float4 l_1 = TexTriplanar_Color( g_tTexture_ps_0, g_sSampler0, (i.vPositionWithOffsetWs.xyz + g_vHighPrecisionLightingOffsetWs.xyz) / 39.3701, normalize( i.vNormalWs.xyz ) );
		float4 l_2 = float4( 0.15623, 0.17898, 0.21084, 1 );
		float4 l_3 = float4( 0.68372, 0.64556, 0.53108, 1 );
		float4 l_4 = float4( 0.56568, 0.62952, 0.2465, 1 );
		float4 l_5 = float4( 0.68675, 0.65055, 0.37647, 1 );
		float3 l_6 = i.vPositionWithOffsetWs.xyz + g_vHighPrecisionLightingOffsetWs.xyz;
		float3 l_7 = l_6 / float3( 512, 512, 512 );
		float l_8 = ValueNoise( l_7.xy );
		float4 l_9 = lerp( l_4, l_5, l_8 );
		float3 l_10 = i.vPositionWithOffsetWs.xyz + g_vHighPrecisionLightingOffsetWs.xyz;
		float l_11 = l_10.z;
		float l_12 = i.vNormalWs.z;
		float l_13 = 1 - l_12;
		float l_14 = l_13 * 256;
		float l_15 = 672 - l_14;
		float4 l_16 = l_11 < l_15 ? l_3 : l_9;
		float l_17 = saturate( ( l_11 - 512 ) / ( 4096 - 512 ) ) * ( 1 - 0.75 ) + 0.75;
		float4 l_18 = l_12 < l_17 ? l_2 : l_16;
		float4 l_19 = l_1 * l_18;
		float4 l_20 = l_0 * l_19;
		float3 l_21 = g_v_SdfCursorPosition;
		float3 l_22 = l_10 - l_21;
		float l_23 = length( l_22 );
		float l_24 = g_fl_SdfCursorRadius;
		float l_25 = l_23 - l_24;
		float l_26 = abs( l_25 );
		float l_27 = l_26 / 16;
		float l_28 = pow( l_27, 0.5 );
		float l_29 = l_25 < 0 ? 0.75 : 1;
		float l_30 = min( l_28, l_29 );
		float4 l_31 = g_v_SdfCursorColor;
		float4 l_32 = l_31 * float4( l_31.a, l_31.a, l_31.a, l_31.a );
		float4 l_33 = saturate( ( float4( l_30, l_30, l_30, l_30 ) - float4( 0, 0, 0, 0 ) ) / ( float4( 1, 1, 1, 1 ) - float4( 0, 0, 0, 0 ) ) ) * ( float4( 0, 0, 0, 0 ) - l_32 ) + l_32;
		float l_34 = l_0.w;
		
		m.Albedo = l_20.xyz;
		m.Emission = l_33.xyz;
		m.Opacity = l_34;
		m.Roughness = 1;
		m.Metalness = 0;
		m.AmbientOcclusion = 1;
		
		m.AmbientOcclusion = saturate( m.AmbientOcclusion );
		m.Roughness = saturate( m.Roughness );
		m.Metalness = saturate( m.Metalness );
		m.Opacity = saturate( m.Opacity );

		// Result node takes normal as tangent space, convert it to world space now
		m.Normal = TransformNormal( m.Normal, i.vNormalWs, i.vTangentUWs, i.vTangentVWs );

		// for some toolvis shit
		m.WorldTangentU = i.vTangentUWs;
		m.WorldTangentV = i.vTangentVWs;
        m.TextureCoords = i.vTextureCoords.xy;
		
		float4 result = ShadingModelStandard::Shade( i, m );

		result.a = m.Opacity;

		return result;
	}
}
