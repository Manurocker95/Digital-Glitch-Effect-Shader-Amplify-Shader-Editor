// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "BandGlitchLit"
{
	Properties
	{
		_ScaleTime("Scale Time", Float) = 1
		_Albedo("Albedo", 2D) = "white" {}
		_BaseColor("BaseColor", Color) = (1,1,1,0)
		_Normal("Normal", 2D) = "white" {}
		_MetallicMap("Metallic Map", 2D) = "white" {}
		_MetallicStrength("Metallic Strength", Float) = 1
		_Occlusion("Occlusion", Float) = 1
		_Smoothness("Smoothness", Float) = 0.5
		[HDR]_Emission("Emission", Color) = (0,0,0,0)
		_Alpha("Alpha", Float) = 1
		[Toggle]_InvertAlpha("Invert Alpha", Float) = 1
		[Toggle]_AlphaClipping("Alpha Clipping", Float) = 1
		_CellDivisionAmount("Cell Division Amount", Float) = 2
		_DeformationStrength("DeformationStrength", Float) = 1
		_NoiseSpeed("NoiseSpeed", Float) = 15
		_BandCenterlength("Band Center length", Float) = 1
		[HDR]_GlitchEmissionColor("GlitchEmissionColor", Color) = (1,1,1,0)
		_BandSpeed("Band Speed", Float) = 2
		_BandAxislength("Band Axis length", Float) = 2
		_BlendAxis("BlendAxis", Vector) = (1,0,0,0)
		_BandTransitionLength("Band Transition Length", Float) = 0.1
		[Toggle]_UseFillPercent("Use Fill Percent", Float) = 0
		_Fillpercentage("Fill percentage", Range( 0 , 1)) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

		//_TransmissionShadow( "Transmission Shadow", Range( 0, 1 ) ) = 0.5
		//_TransStrength( "Trans Strength", Range( 0, 50 ) ) = 1
		//_TransNormal( "Trans Normal Distortion", Range( 0, 1 ) ) = 0.5
		//_TransScattering( "Trans Scattering", Range( 1, 50 ) ) = 2
		//_TransDirect( "Trans Direct", Range( 0, 1 ) ) = 0.9
		//_TransAmbient( "Trans Ambient", Range( 0, 1 ) ) = 0.1
		//_TransShadow( "Trans Shadow", Range( 0, 1 ) ) = 0.5
		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25
		//[ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
		//[ToggleOff] _GlossyReflections("Reflections", Float) = 1.0
	}
	
	SubShader
	{
		
		Tags { "RenderType"="Transparent" "Queue"="Transparent" "DisableBatching"="False" }
	LOD 0

		Cull Back
		AlphaToMask Off
		ZWrite Off
		ZTest LEqual
		ColorMask RGBA
		
		Blend Off
		

		CGINCLUDE
		#pragma target 4.0

		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}
		
		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		ENDCG

		
		Pass
		{
			
			Name "ForwardBase"
			Tags { "LightMode"="ForwardBase" }
			
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#define _ALPHABLEND_ON 1
			#define UNITY_STANDARD_USE_DITHER_MASK 1
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#pragma multi_compile_instancing
			#pragma multi_compile __ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _ALPHATEST_ON 1

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#ifndef UNITY_PASS_FORWARDBASE
				#define UNITY_PASS_FORWARDBASE
			#endif
			#include "HLSLSupport.cginc"
			#ifndef UNITY_INSTANCED_LOD_FADE
				#define UNITY_INSTANCED_LOD_FADE
			#endif
			#ifndef UNITY_INSTANCED_SH
				#define UNITY_INSTANCED_SH
			#endif
			#ifndef UNITY_INSTANCED_LIGHTMAPSTS
				#define UNITY_INSTANCED_LIGHTMAPSTS
			#endif
			#include "UnityShaderVariables.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			#include "AutoLight.cginc"

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_TANGENT
			#define ASE_NEEDS_FRAG_POSITION

			struct appdata {
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct v2f {
				#if UNITY_VERSION >= 201810
					UNITY_POSITION(pos);
				#else
					float4 pos : SV_POSITION;
				#endif
				#if defined(LIGHTMAP_ON) || (!defined(LIGHTMAP_ON) && SHADER_TARGET >= 30)
					float4 lmap : TEXCOORD0;
				#endif
				#if !defined(LIGHTMAP_ON) && UNITY_SHOULD_SAMPLE_SH
					half3 sh : TEXCOORD1;
				#endif
				#if defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS) && UNITY_VERSION >= 201810 && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_LIGHTING_COORDS(2,3)
				#elif defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if UNITY_VERSION >= 201710
						UNITY_SHADOW_COORDS(2)
					#else
						SHADOW_COORDS(2)
					#endif
				#endif
				#ifdef ASE_FOG
					UNITY_FOG_COORDS(4)
				#endif
				float4 tSpace0 : TEXCOORD5;
				float4 tSpace1 : TEXCOORD6;
				float4 tSpace2 : TEXCOORD7;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 screenPos : TEXCOORD8;
				#endif
				float4 ase_texcoord9 : TEXCOORD9;
				float4 ase_texcoord10 : TEXCOORD10;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			uniform float _CellDivisionAmount;
			uniform float _ScaleTime;
			uniform float _NoiseSpeed;
			uniform float _DeformationStrength;
			uniform float3 _BlendAxis;
			uniform float _BandCenterlength;
			uniform float _BandAxislength;
			uniform float _UseFillPercent;
			uniform float _BandSpeed;
			uniform float _Fillpercentage;
			uniform float _BandTransitionLength;
			uniform float4 _BaseColor;
			uniform sampler2D _Albedo;
			uniform float4 _Albedo_ST;
			uniform float4 _GlitchEmissionColor;
			uniform sampler2D _Normal;
			uniform float4 _Normal_ST;
			uniform float4 _Emission;
			uniform sampler2D _MetallicMap;
			uniform float4 _MetallicMap_ST;
			uniform float _MetallicStrength;
			uniform float _Smoothness;
			uniform float _Occlusion;
			uniform float _Alpha;
			uniform float _AlphaClipping;
			uniform float _InvertAlpha;

	
			
			v2f VertexFunction (appdata v  ) {
				UNITY_SETUP_INSTANCE_ID(v);
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				UNITY_TRANSFER_INSTANCE_ID(v,o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 break8_g67 = ( v.vertex.xyz / ( _CellDivisionAmount / 100.0 ) );
				float mulTime15_g67 = _Time.y * _ScaleTime;
				float temp_output_13_0_g67 = ( frac( ( sin( mulTime15_g67 ) * ( 53270.0 + 0.0 ) ) ) * _NoiseSpeed );
				float4 appendResult10_g67 = (float4(( break8_g67.x + temp_output_13_0_g67 ) , ( break8_g67.y + temp_output_13_0_g67 ) , ( break8_g67.z + temp_output_13_0_g67 ) , 0.0));
				float3 temp_output_13_0_g69 = ceil( appendResult10_g67 ).xyz;
				float dotResult12_g69 = dot( temp_output_13_0_g69 , float3(15400,28700,38700) );
				float dotResult15_g69 = dot( temp_output_13_0_g69 , float3(35300,51700,79500) );
				float dotResult17_g69 = dot( temp_output_13_0_g69 , float3(49700,20800,73000) );
				float3 appendResult11_g69 = (float3(dotResult12_g69 , dotResult15_g69 , dotResult17_g69));
				float3 temp_cast_1 = (1.0).xxx;
				float3 temp_output_72_0_g64 = (float3( 0,0,0 ) + (( ( frac( ( sin( appendResult11_g69 ) * ( 42940.0 + 0.0 ) ) ) * 2.0 ) - temp_cast_1 ) - float3( -1,-1,-1 )) * (float3( 1,1,1 ) - float3( 0,0,0 )) / (float3( 1,1,1 ) - float3( -1,-1,-1 )));
				float3 break27_g57 = _BlendAxis;
				float3 break24_g57 = v.vertex.xyz;
				float mulTime17_g57 = _Time.y * _ScaleTime;
				float temp_output_6_0_g57 = ( ( ( break27_g57.x == 1.0 ? break24_g57.x : ( break27_g57.y == 1.0 ? break24_g57.y : break24_g57.z ) ) + _BandCenterlength ) - ( _BandAxislength * (( _UseFillPercent )?( _Fillpercentage ):( (0.0 + (sin( ( _BandSpeed * mulTime17_g57 ) ) - -1.0) * (1.0 - 0.0) / (1.0 - -1.0)) )) ) );
				float smoothstepResult2_g57 = smoothstep( 0.0 , 1.0 , ( distance( temp_output_6_0_g57 , 0.0 ) / _BandTransitionLength ));
				float clampResult1_g57 = clamp( smoothstepResult2_g57 , 0.0 , 1.0 );
				float temp_output_47_0_g64 = clampResult1_g57;
				float3 lerpResult4_g66 = lerp( ( ( temp_output_72_0_g64 * v.normal ) * ( _DeformationStrength / 100.0 ) ) , float3( 0,0,0 ) , temp_output_47_0_g64);
				
				o.ase_texcoord9.xy = v.ase_texcoord.xy;
				o.ase_texcoord10 = v.vertex;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord9.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( v.vertex.xyz + lerpResult4_g66 );
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.vertex.w = 1;
				v.normal = v.normal;
				v.tangent = float4( v.tangent.xyz , 0.0 );

				o.pos = UnityObjectToClipPos(v.vertex);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
				o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				#ifdef DYNAMICLIGHTMAP_ON
				o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif
				#ifdef LIGHTMAP_ON
				o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				#ifndef LIGHTMAP_ON
					#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
						o.sh = 0;
						#ifdef VERTEXLIGHT_ON
						o.sh += Shade4PointLights (
							unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
							unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
							unity_4LightAtten0, worldPos, worldNormal);
						#endif
						o.sh = ShadeSHPerVertex (worldNormal, o.sh);
					#endif
				#endif

				#if UNITY_VERSION >= 201810 && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_TRANSFER_LIGHTING(o, v.texcoord1.xy);
				#elif defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if UNITY_VERSION >= 201710
						UNITY_TRANSFER_SHADOW(o, v.texcoord1.xy);
					#else
						TRANSFER_SHADOW(o);
					#endif
				#endif

				#ifdef ASE_FOG
					UNITY_TRANSFER_FOG(o,o.pos);
				#endif
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
					o.screenPos = ComputeScreenPos(o.pos);
				#endif
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( appdata v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				appdata o = (appdata) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
				o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			v2f vert ( appdata v )
			{
				return VertexFunction( v );
			}
			#endif
			
			fixed4 frag (v2f IN 
				#ifdef _DEPTHOFFSET_ON
				, out float outputDepth : SV_Depth
				#endif
				) : SV_Target 
			{
				UNITY_SETUP_INSTANCE_ID(IN);

				#ifdef LOD_FADE_CROSSFADE
					UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
				#endif

				#if defined(_SPECULAR_SETUP)
					SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
				#else
					SurfaceOutputStandard o = (SurfaceOutputStandard)0;
				#endif
				float3 WorldTangent = float3(IN.tSpace0.x,IN.tSpace1.x,IN.tSpace2.x);
				float3 WorldBiTangent = float3(IN.tSpace0.y,IN.tSpace1.y,IN.tSpace2.y);
				float3 WorldNormal = float3(IN.tSpace0.z,IN.tSpace1.z,IN.tSpace2.z);
				float3 worldPos = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
				#else
					half atten = 1;
				#endif
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 ScreenPos = IN.screenPos;
				#endif

				float2 uv_Albedo = IN.ase_texcoord9.xy * _Albedo_ST.xy + _Albedo_ST.zw;
				float4 temp_output_1_0_g50 = ( _BaseColor * tex2D( _Albedo, uv_Albedo ) );
				float3 break8_g67 = ( IN.ase_texcoord10.xyz / ( _CellDivisionAmount / 100.0 ) );
				float mulTime15_g67 = _Time.y * _ScaleTime;
				float temp_output_13_0_g67 = ( frac( ( sin( mulTime15_g67 ) * ( 53270.0 + 0.0 ) ) ) * _NoiseSpeed );
				float4 appendResult10_g67 = (float4(( break8_g67.x + temp_output_13_0_g67 ) , ( break8_g67.y + temp_output_13_0_g67 ) , ( break8_g67.z + temp_output_13_0_g67 ) , 0.0));
				float3 temp_output_13_0_g69 = ceil( appendResult10_g67 ).xyz;
				float dotResult12_g69 = dot( temp_output_13_0_g69 , float3(15400,28700,38700) );
				float dotResult15_g69 = dot( temp_output_13_0_g69 , float3(35300,51700,79500) );
				float dotResult17_g69 = dot( temp_output_13_0_g69 , float3(49700,20800,73000) );
				float3 appendResult11_g69 = (float3(dotResult12_g69 , dotResult15_g69 , dotResult17_g69));
				float3 temp_cast_2 = (1.0).xxx;
				float3 temp_output_72_0_g64 = (float3( 0,0,0 ) + (( ( frac( ( sin( appendResult11_g69 ) * ( 42940.0 + 0.0 ) ) ) * 2.0 ) - temp_cast_2 ) - float3( -1,-1,-1 )) * (float3( 1,1,1 ) - float3( 0,0,0 )) / (float3( 1,1,1 ) - float3( -1,-1,-1 )));
				float3 clampResult30_g64 = clamp( pow( temp_output_72_0_g64 , float3(4,4,4) ) , float3( 0,0,0 ) , float3( 1,1,1 ) );
				float3 break27_g57 = _BlendAxis;
				float3 break24_g57 = IN.ase_texcoord10.xyz;
				float mulTime17_g57 = _Time.y * _ScaleTime;
				float temp_output_6_0_g57 = ( ( ( break27_g57.x == 1.0 ? break24_g57.x : ( break27_g57.y == 1.0 ? break24_g57.y : break24_g57.z ) ) + _BandCenterlength ) - ( _BandAxislength * (( _UseFillPercent )?( _Fillpercentage ):( (0.0 + (sin( ( _BandSpeed * mulTime17_g57 ) ) - -1.0) * (1.0 - 0.0) / (1.0 - -1.0)) )) ) );
				float smoothstepResult2_g57 = smoothstep( 0.0 , 1.0 , ( distance( temp_output_6_0_g57 , 0.0 ) / _BandTransitionLength ));
				float clampResult1_g57 = clamp( smoothstepResult2_g57 , 0.0 , 1.0 );
				float temp_output_47_0_g64 = clampResult1_g57;
				float4 lerpResult6_g65 = lerp( ( float4( ( clampResult30_g64 * float3(10,10,10) ) , 0.0 ) * _GlitchEmissionColor ) , _BaseColor , temp_output_47_0_g64);
				float4 temp_cast_6 = (1.0).xxxx;
				float4 lerpResult7_g50 = lerp( temp_output_1_0_g50 , ( ( temp_output_1_0_g50 + lerpResult6_g65 ) - temp_cast_6 ) , 1.0);
				
				float2 uv_Normal = IN.ase_texcoord9.xy * _Normal_ST.xy + _Normal_ST.zw;
				float4 tex2DNode46 = tex2D( _Normal, uv_Normal );
				
				float2 uv_MetallicMap = IN.ase_texcoord9.xy * _MetallicMap_ST.xy + _MetallicMap_ST.zw;
				
				float temp_output_94_8 = temp_output_6_0_g57;
				float clampResult8_g64 = clamp( ( (( _InvertAlpha )?( temp_output_94_8 ):( ( 1.0 - temp_output_94_8 ) )) - ( temp_output_72_0_g64.x * 0.02 ) ) , 0.0 , 1.0 );
				
				o.Albedo = lerpResult7_g50.xyz;
				o.Normal = tex2DNode46.rgb;
				o.Emission = _Emission.rgb;
				#if defined(_SPECULAR_SETUP)
					o.Specular = fixed3( 0, 0, 0 );
				#else
					o.Metallic = ( tex2D( _MetallicMap, uv_MetallicMap ) * _MetallicStrength ).r;
				#endif
				o.Smoothness = _Smoothness;
				o.Occlusion = _Occlusion;
				o.Alpha = _Alpha;
				float AlphaClipThreshold = (( _AlphaClipping )?( (1.0 + (clampResult8_g64 - 0.0) * (2.0 - 1.0) / (1.0 - 0.0)) ):( 1.0 ));
				float AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;				

				#ifdef _ALPHATEST_ON
					clip( o.Alpha - AlphaClipThreshold );
				#endif

				#ifdef _DEPTHOFFSET_ON
					outputDepth = IN.pos.z;
				#endif

				#ifndef USING_DIRECTIONAL_LIGHT
					fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				#else
					fixed3 lightDir = _WorldSpaceLightPos0.xyz;
				#endif

				fixed4 c = 0;
				float3 worldN;
				worldN.x = dot(IN.tSpace0.xyz, o.Normal);
				worldN.y = dot(IN.tSpace1.xyz, o.Normal);
				worldN.z = dot(IN.tSpace2.xyz, o.Normal);
				worldN = normalize(worldN);
				o.Normal = worldN;

				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
				gi.indirect.diffuse = 0;
				gi.indirect.specular = 0;
				gi.light.color = _LightColor0.rgb;
				gi.light.dir = lightDir;

				UnityGIInput giInput;
				UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
				giInput.light = gi.light;
				giInput.worldPos = worldPos;
				giInput.worldViewDir = worldViewDir;
				giInput.atten = atten;
				#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
					giInput.lightmapUV = IN.lmap;
				#else
					giInput.lightmapUV = 0.0;
				#endif
				#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
					giInput.ambient = IN.sh;
				#else
					giInput.ambient.rgb = 0.0;
				#endif
				giInput.probeHDR[0] = unity_SpecCube0_HDR;
				giInput.probeHDR[1] = unity_SpecCube1_HDR;
				#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
					giInput.boxMin[0] = unity_SpecCube0_BoxMin;
				#endif
				#ifdef UNITY_SPECCUBE_BOX_PROJECTION
					giInput.boxMax[0] = unity_SpecCube0_BoxMax;
					giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
					giInput.boxMax[1] = unity_SpecCube1_BoxMax;
					giInput.boxMin[1] = unity_SpecCube1_BoxMin;
					giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
				#endif
				
				#if defined(_SPECULAR_SETUP)
					LightingStandardSpecular_GI(o, giInput, gi);
				#else
					LightingStandard_GI( o, giInput, gi );
				#endif

				#ifdef ASE_BAKEDGI
					gi.indirect.diffuse = BakedGI;
				#endif

				#if UNITY_SHOULD_SAMPLE_SH && !defined(LIGHTMAP_ON) && defined(ASE_NO_AMBIENT)
					gi.indirect.diffuse = 0;
				#endif

				#if defined(_SPECULAR_SETUP)
					c += LightingStandardSpecular (o, worldViewDir, gi);
				#else
					c += LightingStandard( o, worldViewDir, gi );
				#endif
				
				#ifdef _TRANSMISSION_ASE
				{
					float shadow = _TransmissionShadow;
					#ifdef DIRECTIONAL
						float3 lightAtten = lerp( _LightColor0.rgb, gi.light.color, shadow );
					#else
						float3 lightAtten = gi.light.color;
					#endif
					half3 transmission = max(0 , -dot(o.Normal, gi.light.dir)) * lightAtten * Transmission;
					c.rgb += o.Albedo * transmission;
				}
				#endif

				#ifdef _TRANSLUCENCY_ASE
				{
					float shadow = _TransShadow;
					float normal = _TransNormal;
					float scattering = _TransScattering;
					float direct = _TransDirect;
					float ambient = _TransAmbient;
					float strength = _TransStrength;

					#ifdef DIRECTIONAL
						float3 lightAtten = lerp( _LightColor0.rgb, gi.light.color, shadow );
					#else
						float3 lightAtten = gi.light.color;
					#endif
					half3 lightDir = gi.light.dir + o.Normal * normal;
					half transVdotL = pow( saturate( dot( worldViewDir, -lightDir ) ), scattering );
					half3 translucency = lightAtten * (transVdotL * direct + gi.indirect.diffuse * ambient) * Translucency;
					c.rgb += o.Albedo * translucency * strength;
				}
				#endif

				//#ifdef _REFRACTION_ASE
				//	float4 projScreenPos = ScreenPos / ScreenPos.w;
				//	float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, WorldNormal ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
				//	projScreenPos.xy += refractionOffset.xy;
				//	float3 refraction = UNITY_SAMPLE_SCREENSPACE_TEXTURE( _GrabTexture, projScreenPos ) * RefractionColor;
				//	color.rgb = lerp( refraction, color.rgb, color.a );
				//	color.a = 1;
				//#endif

				c.rgb += o.Emission;

				#ifdef ASE_FOG
					UNITY_APPLY_FOG(IN.fogCoord, c);
				#endif
				return c;
			}
			ENDCG
		}

		
		Pass
		{
			
			Name "ForwardAdd"
			Tags { "LightMode"="ForwardAdd" }
			ZWrite Off
			Blend SrcAlpha One

			CGPROGRAM
			#define _ALPHABLEND_ON 1
			#define UNITY_STANDARD_USE_DITHER_MASK 1
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#pragma multi_compile_instancing
			#pragma multi_compile __ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _ALPHATEST_ON 1

			#pragma vertex vert
			#pragma fragment frag
			#pragma skip_variants INSTANCING_ON
			#pragma multi_compile_fwdadd_fullshadows
			#ifndef UNITY_PASS_FORWARDADD
				#define UNITY_PASS_FORWARDADD
			#endif
			#include "HLSLSupport.cginc"
			#if !defined( UNITY_INSTANCED_LOD_FADE )
				#define UNITY_INSTANCED_LOD_FADE
			#endif
			#if !defined( UNITY_INSTANCED_SH )
				#define UNITY_INSTANCED_SH
			#endif
			#if !defined( UNITY_INSTANCED_LIGHTMAPSTS )
				#define UNITY_INSTANCED_LIGHTMAPSTS
			#endif
			#include "UnityShaderVariables.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			#include "AutoLight.cginc"

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_TANGENT
			#define ASE_NEEDS_FRAG_POSITION

			struct appdata {
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			struct v2f {
				#if UNITY_VERSION >= 201810
					UNITY_POSITION(pos);
				#else
					float4 pos : SV_POSITION;
				#endif
				#if UNITY_VERSION >= 201810 && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_LIGHTING_COORDS(1,2)
				#elif defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if UNITY_VERSION >= 201710
						UNITY_SHADOW_COORDS(1)
					#else
						SHADOW_COORDS(1)
					#endif
				#endif
				#ifdef ASE_FOG
					UNITY_FOG_COORDS(3)
				#endif
				float4 tSpace0 : TEXCOORD5;
				float4 tSpace1 : TEXCOORD6;
				float4 tSpace2 : TEXCOORD7;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 screenPos : TEXCOORD8;
				#endif
				float4 ase_texcoord9 : TEXCOORD9;
				float4 ase_texcoord10 : TEXCOORD10;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			uniform float _CellDivisionAmount;
			uniform float _ScaleTime;
			uniform float _NoiseSpeed;
			uniform float _DeformationStrength;
			uniform float3 _BlendAxis;
			uniform float _BandCenterlength;
			uniform float _BandAxislength;
			uniform float _UseFillPercent;
			uniform float _BandSpeed;
			uniform float _Fillpercentage;
			uniform float _BandTransitionLength;
			uniform float4 _BaseColor;
			uniform sampler2D _Albedo;
			uniform float4 _Albedo_ST;
			uniform float4 _GlitchEmissionColor;
			uniform sampler2D _Normal;
			uniform float4 _Normal_ST;
			uniform float4 _Emission;
			uniform sampler2D _MetallicMap;
			uniform float4 _MetallicMap_ST;
			uniform float _MetallicStrength;
			uniform float _Smoothness;
			uniform float _Occlusion;
			uniform float _Alpha;
			uniform float _AlphaClipping;
			uniform float _InvertAlpha;

	
			
			v2f VertexFunction (appdata v  ) {
				UNITY_SETUP_INSTANCE_ID(v);
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				UNITY_TRANSFER_INSTANCE_ID(v,o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 break8_g67 = ( v.vertex.xyz / ( _CellDivisionAmount / 100.0 ) );
				float mulTime15_g67 = _Time.y * _ScaleTime;
				float temp_output_13_0_g67 = ( frac( ( sin( mulTime15_g67 ) * ( 53270.0 + 0.0 ) ) ) * _NoiseSpeed );
				float4 appendResult10_g67 = (float4(( break8_g67.x + temp_output_13_0_g67 ) , ( break8_g67.y + temp_output_13_0_g67 ) , ( break8_g67.z + temp_output_13_0_g67 ) , 0.0));
				float3 temp_output_13_0_g69 = ceil( appendResult10_g67 ).xyz;
				float dotResult12_g69 = dot( temp_output_13_0_g69 , float3(15400,28700,38700) );
				float dotResult15_g69 = dot( temp_output_13_0_g69 , float3(35300,51700,79500) );
				float dotResult17_g69 = dot( temp_output_13_0_g69 , float3(49700,20800,73000) );
				float3 appendResult11_g69 = (float3(dotResult12_g69 , dotResult15_g69 , dotResult17_g69));
				float3 temp_cast_1 = (1.0).xxx;
				float3 temp_output_72_0_g64 = (float3( 0,0,0 ) + (( ( frac( ( sin( appendResult11_g69 ) * ( 42940.0 + 0.0 ) ) ) * 2.0 ) - temp_cast_1 ) - float3( -1,-1,-1 )) * (float3( 1,1,1 ) - float3( 0,0,0 )) / (float3( 1,1,1 ) - float3( -1,-1,-1 )));
				float3 break27_g57 = _BlendAxis;
				float3 break24_g57 = v.vertex.xyz;
				float mulTime17_g57 = _Time.y * _ScaleTime;
				float temp_output_6_0_g57 = ( ( ( break27_g57.x == 1.0 ? break24_g57.x : ( break27_g57.y == 1.0 ? break24_g57.y : break24_g57.z ) ) + _BandCenterlength ) - ( _BandAxislength * (( _UseFillPercent )?( _Fillpercentage ):( (0.0 + (sin( ( _BandSpeed * mulTime17_g57 ) ) - -1.0) * (1.0 - 0.0) / (1.0 - -1.0)) )) ) );
				float smoothstepResult2_g57 = smoothstep( 0.0 , 1.0 , ( distance( temp_output_6_0_g57 , 0.0 ) / _BandTransitionLength ));
				float clampResult1_g57 = clamp( smoothstepResult2_g57 , 0.0 , 1.0 );
				float temp_output_47_0_g64 = clampResult1_g57;
				float3 lerpResult4_g66 = lerp( ( ( temp_output_72_0_g64 * v.normal ) * ( _DeformationStrength / 100.0 ) ) , float3( 0,0,0 ) , temp_output_47_0_g64);
				
				o.ase_texcoord9.xy = v.ase_texcoord.xy;
				o.ase_texcoord10 = v.vertex;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord9.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( v.vertex.xyz + lerpResult4_g66 );
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.vertex.w = 1;
				v.normal = v.normal;
				v.tangent = float4( v.tangent.xyz , 0.0 );

				o.pos = UnityObjectToClipPos(v.vertex);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
				o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				#if UNITY_VERSION >= 201810 && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_TRANSFER_LIGHTING(o, v.texcoord1.xy);
				#elif defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if UNITY_VERSION >= 201710
						UNITY_TRANSFER_SHADOW(o, v.texcoord1.xy);
					#else
						TRANSFER_SHADOW(o);
					#endif
				#endif

				#ifdef ASE_FOG
					UNITY_TRANSFER_FOG(o,o.pos);
				#endif
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
					o.screenPos = ComputeScreenPos(o.pos);
				#endif
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( appdata v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				appdata o = (appdata) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
				o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			v2f vert ( appdata v )
			{
				return VertexFunction( v );
			}
			#endif

			fixed4 frag ( v2f IN 
				#ifdef _DEPTHOFFSET_ON
				, out float outputDepth : SV_Depth
				#endif
				) : SV_Target 
			{
				UNITY_SETUP_INSTANCE_ID(IN);

				#ifdef LOD_FADE_CROSSFADE
					UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
				#endif

				#if defined(_SPECULAR_SETUP)
					SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
				#else
					SurfaceOutputStandard o = (SurfaceOutputStandard)0;
				#endif
				float3 WorldTangent = float3(IN.tSpace0.x,IN.tSpace1.x,IN.tSpace2.x);
				float3 WorldBiTangent = float3(IN.tSpace0.y,IN.tSpace1.y,IN.tSpace2.y);
				float3 WorldNormal = float3(IN.tSpace0.z,IN.tSpace1.z,IN.tSpace2.z);
				float3 worldPos = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
				#else
					half atten = 1;
				#endif
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 ScreenPos = IN.screenPos;
				#endif


				float2 uv_Albedo = IN.ase_texcoord9.xy * _Albedo_ST.xy + _Albedo_ST.zw;
				float4 temp_output_1_0_g50 = ( _BaseColor * tex2D( _Albedo, uv_Albedo ) );
				float3 break8_g67 = ( IN.ase_texcoord10.xyz / ( _CellDivisionAmount / 100.0 ) );
				float mulTime15_g67 = _Time.y * _ScaleTime;
				float temp_output_13_0_g67 = ( frac( ( sin( mulTime15_g67 ) * ( 53270.0 + 0.0 ) ) ) * _NoiseSpeed );
				float4 appendResult10_g67 = (float4(( break8_g67.x + temp_output_13_0_g67 ) , ( break8_g67.y + temp_output_13_0_g67 ) , ( break8_g67.z + temp_output_13_0_g67 ) , 0.0));
				float3 temp_output_13_0_g69 = ceil( appendResult10_g67 ).xyz;
				float dotResult12_g69 = dot( temp_output_13_0_g69 , float3(15400,28700,38700) );
				float dotResult15_g69 = dot( temp_output_13_0_g69 , float3(35300,51700,79500) );
				float dotResult17_g69 = dot( temp_output_13_0_g69 , float3(49700,20800,73000) );
				float3 appendResult11_g69 = (float3(dotResult12_g69 , dotResult15_g69 , dotResult17_g69));
				float3 temp_cast_2 = (1.0).xxx;
				float3 temp_output_72_0_g64 = (float3( 0,0,0 ) + (( ( frac( ( sin( appendResult11_g69 ) * ( 42940.0 + 0.0 ) ) ) * 2.0 ) - temp_cast_2 ) - float3( -1,-1,-1 )) * (float3( 1,1,1 ) - float3( 0,0,0 )) / (float3( 1,1,1 ) - float3( -1,-1,-1 )));
				float3 clampResult30_g64 = clamp( pow( temp_output_72_0_g64 , float3(4,4,4) ) , float3( 0,0,0 ) , float3( 1,1,1 ) );
				float3 break27_g57 = _BlendAxis;
				float3 break24_g57 = IN.ase_texcoord10.xyz;
				float mulTime17_g57 = _Time.y * _ScaleTime;
				float temp_output_6_0_g57 = ( ( ( break27_g57.x == 1.0 ? break24_g57.x : ( break27_g57.y == 1.0 ? break24_g57.y : break24_g57.z ) ) + _BandCenterlength ) - ( _BandAxislength * (( _UseFillPercent )?( _Fillpercentage ):( (0.0 + (sin( ( _BandSpeed * mulTime17_g57 ) ) - -1.0) * (1.0 - 0.0) / (1.0 - -1.0)) )) ) );
				float smoothstepResult2_g57 = smoothstep( 0.0 , 1.0 , ( distance( temp_output_6_0_g57 , 0.0 ) / _BandTransitionLength ));
				float clampResult1_g57 = clamp( smoothstepResult2_g57 , 0.0 , 1.0 );
				float temp_output_47_0_g64 = clampResult1_g57;
				float4 lerpResult6_g65 = lerp( ( float4( ( clampResult30_g64 * float3(10,10,10) ) , 0.0 ) * _GlitchEmissionColor ) , _BaseColor , temp_output_47_0_g64);
				float4 temp_cast_6 = (1.0).xxxx;
				float4 lerpResult7_g50 = lerp( temp_output_1_0_g50 , ( ( temp_output_1_0_g50 + lerpResult6_g65 ) - temp_cast_6 ) , 1.0);
				
				float2 uv_Normal = IN.ase_texcoord9.xy * _Normal_ST.xy + _Normal_ST.zw;
				float4 tex2DNode46 = tex2D( _Normal, uv_Normal );
				
				float2 uv_MetallicMap = IN.ase_texcoord9.xy * _MetallicMap_ST.xy + _MetallicMap_ST.zw;
				
				float temp_output_94_8 = temp_output_6_0_g57;
				float clampResult8_g64 = clamp( ( (( _InvertAlpha )?( temp_output_94_8 ):( ( 1.0 - temp_output_94_8 ) )) - ( temp_output_72_0_g64.x * 0.02 ) ) , 0.0 , 1.0 );
				
				o.Albedo = lerpResult7_g50.xyz;
				o.Normal = tex2DNode46.rgb;
				o.Emission = _Emission.rgb;
				#if defined(_SPECULAR_SETUP)
					o.Specular = fixed3( 0, 0, 0 );
				#else
					o.Metallic = ( tex2D( _MetallicMap, uv_MetallicMap ) * _MetallicStrength ).r;
				#endif
				o.Smoothness = _Smoothness;
				o.Occlusion = _Occlusion;
				o.Alpha = _Alpha;
				float AlphaClipThreshold = (( _AlphaClipping )?( (1.0 + (clampResult8_g64 - 0.0) * (2.0 - 1.0) / (1.0 - 0.0)) ):( 1.0 ));
				float3 Transmission = 1;
				float3 Translucency = 1;		

				#ifdef _ALPHATEST_ON
					clip( o.Alpha - AlphaClipThreshold );
				#endif

				#ifdef _DEPTHOFFSET_ON
					outputDepth = IN.pos.z;
				#endif

				#ifndef USING_DIRECTIONAL_LIGHT
					fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				#else
					fixed3 lightDir = _WorldSpaceLightPos0.xyz;
				#endif

				fixed4 c = 0;
				float3 worldN;
				worldN.x = dot(IN.tSpace0.xyz, o.Normal);
				worldN.y = dot(IN.tSpace1.xyz, o.Normal);
				worldN.z = dot(IN.tSpace2.xyz, o.Normal);
				worldN = normalize(worldN);
				o.Normal = worldN;

				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
				gi.indirect.diffuse = 0;
				gi.indirect.specular = 0;
				gi.light.color = _LightColor0.rgb;
				gi.light.dir = lightDir;
				gi.light.color *= atten;

				#if defined(_SPECULAR_SETUP)
					c += LightingStandardSpecular( o, worldViewDir, gi );
				#else
					c += LightingStandard( o, worldViewDir, gi );
				#endif
				
				#ifdef _TRANSMISSION_ASE
				{
					float shadow = _TransmissionShadow;
					#ifdef DIRECTIONAL
						float3 lightAtten = lerp( _LightColor0.rgb, gi.light.color, shadow );
					#else
						float3 lightAtten = gi.light.color;
					#endif
					half3 transmission = max(0 , -dot(o.Normal, gi.light.dir)) * lightAtten * Transmission;
					c.rgb += o.Albedo * transmission;
				}
				#endif

				#ifdef _TRANSLUCENCY_ASE
				{
					float shadow = _TransShadow;
					float normal = _TransNormal;
					float scattering = _TransScattering;
					float direct = _TransDirect;
					float ambient = _TransAmbient;
					float strength = _TransStrength;

					#ifdef DIRECTIONAL
						float3 lightAtten = lerp( _LightColor0.rgb, gi.light.color, shadow );
					#else
						float3 lightAtten = gi.light.color;
					#endif
					half3 lightDir = gi.light.dir + o.Normal * normal;
					half transVdotL = pow( saturate( dot( worldViewDir, -lightDir ) ), scattering );
					half3 translucency = lightAtten * (transVdotL * direct + gi.indirect.diffuse * ambient) * Translucency;
					c.rgb += o.Albedo * translucency * strength;
				}
				#endif

				//#ifdef _REFRACTION_ASE
				//	float4 projScreenPos = ScreenPos / ScreenPos.w;
				//	float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, WorldNormal ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
				//	projScreenPos.xy += refractionOffset.xy;
				//	float3 refraction = UNITY_SAMPLE_SCREENSPACE_TEXTURE( _GrabTexture, projScreenPos ) * RefractionColor;
				//	color.rgb = lerp( refraction, color.rgb, color.a );
				//	color.a = 1;
				//#endif

				#ifdef ASE_FOG
					UNITY_APPLY_FOG(IN.fogCoord, c);
				#endif
				return c;
			}
			ENDCG
		}

		
		Pass
		{
			
			Name "Deferred"
			Tags { "LightMode"="Deferred" }

			AlphaToMask Off

			CGPROGRAM
			#define _ALPHABLEND_ON 1
			#define UNITY_STANDARD_USE_DITHER_MASK 1
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#pragma multi_compile_instancing
			#pragma multi_compile __ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _ALPHATEST_ON 1

			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma exclude_renderers nomrt
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#pragma multi_compile_prepassfinal
			#ifndef UNITY_PASS_DEFERRED
				#define UNITY_PASS_DEFERRED
			#endif
			#include "HLSLSupport.cginc"
			#if !defined( UNITY_INSTANCED_LOD_FADE )
				#define UNITY_INSTANCED_LOD_FADE
			#endif
			#if !defined( UNITY_INSTANCED_SH )
				#define UNITY_INSTANCED_SH
			#endif
			#if !defined( UNITY_INSTANCED_LIGHTMAPSTS )
				#define UNITY_INSTANCED_LIGHTMAPSTS
			#endif
			#include "UnityShaderVariables.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_TANGENT
			#define ASE_NEEDS_FRAG_POSITION

			struct appdata {
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f {
				#if UNITY_VERSION >= 201810
					UNITY_POSITION(pos);
				#else
					float4 pos : SV_POSITION;
				#endif
				float4 lmap : TEXCOORD2;
				#ifndef LIGHTMAP_ON
					#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
						half3 sh : TEXCOORD3;
					#endif
				#else
					#ifdef DIRLIGHTMAP_OFF
						float4 lmapFadePos : TEXCOORD4;
					#endif
				#endif
				float4 tSpace0 : TEXCOORD5;
				float4 tSpace1 : TEXCOORD6;
				float4 tSpace2 : TEXCOORD7;
				float4 ase_texcoord8 : TEXCOORD8;
				float4 ase_texcoord9 : TEXCOORD9;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#ifdef LIGHTMAP_ON
			float4 unity_LightmapFade;
			#endif
			fixed4 unity_Ambient;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			uniform float _CellDivisionAmount;
			uniform float _ScaleTime;
			uniform float _NoiseSpeed;
			uniform float _DeformationStrength;
			uniform float3 _BlendAxis;
			uniform float _BandCenterlength;
			uniform float _BandAxislength;
			uniform float _UseFillPercent;
			uniform float _BandSpeed;
			uniform float _Fillpercentage;
			uniform float _BandTransitionLength;
			uniform float4 _BaseColor;
			uniform sampler2D _Albedo;
			uniform float4 _Albedo_ST;
			uniform float4 _GlitchEmissionColor;
			uniform sampler2D _Normal;
			uniform float4 _Normal_ST;
			uniform float4 _Emission;
			uniform sampler2D _MetallicMap;
			uniform float4 _MetallicMap_ST;
			uniform float _MetallicStrength;
			uniform float _Smoothness;
			uniform float _Occlusion;
			uniform float _Alpha;
			uniform float _AlphaClipping;
			uniform float _InvertAlpha;

	
			
			v2f VertexFunction (appdata v  ) {
				UNITY_SETUP_INSTANCE_ID(v);
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				UNITY_TRANSFER_INSTANCE_ID(v,o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 break8_g67 = ( v.vertex.xyz / ( _CellDivisionAmount / 100.0 ) );
				float mulTime15_g67 = _Time.y * _ScaleTime;
				float temp_output_13_0_g67 = ( frac( ( sin( mulTime15_g67 ) * ( 53270.0 + 0.0 ) ) ) * _NoiseSpeed );
				float4 appendResult10_g67 = (float4(( break8_g67.x + temp_output_13_0_g67 ) , ( break8_g67.y + temp_output_13_0_g67 ) , ( break8_g67.z + temp_output_13_0_g67 ) , 0.0));
				float3 temp_output_13_0_g69 = ceil( appendResult10_g67 ).xyz;
				float dotResult12_g69 = dot( temp_output_13_0_g69 , float3(15400,28700,38700) );
				float dotResult15_g69 = dot( temp_output_13_0_g69 , float3(35300,51700,79500) );
				float dotResult17_g69 = dot( temp_output_13_0_g69 , float3(49700,20800,73000) );
				float3 appendResult11_g69 = (float3(dotResult12_g69 , dotResult15_g69 , dotResult17_g69));
				float3 temp_cast_1 = (1.0).xxx;
				float3 temp_output_72_0_g64 = (float3( 0,0,0 ) + (( ( frac( ( sin( appendResult11_g69 ) * ( 42940.0 + 0.0 ) ) ) * 2.0 ) - temp_cast_1 ) - float3( -1,-1,-1 )) * (float3( 1,1,1 ) - float3( 0,0,0 )) / (float3( 1,1,1 ) - float3( -1,-1,-1 )));
				float3 break27_g57 = _BlendAxis;
				float3 break24_g57 = v.vertex.xyz;
				float mulTime17_g57 = _Time.y * _ScaleTime;
				float temp_output_6_0_g57 = ( ( ( break27_g57.x == 1.0 ? break24_g57.x : ( break27_g57.y == 1.0 ? break24_g57.y : break24_g57.z ) ) + _BandCenterlength ) - ( _BandAxislength * (( _UseFillPercent )?( _Fillpercentage ):( (0.0 + (sin( ( _BandSpeed * mulTime17_g57 ) ) - -1.0) * (1.0 - 0.0) / (1.0 - -1.0)) )) ) );
				float smoothstepResult2_g57 = smoothstep( 0.0 , 1.0 , ( distance( temp_output_6_0_g57 , 0.0 ) / _BandTransitionLength ));
				float clampResult1_g57 = clamp( smoothstepResult2_g57 , 0.0 , 1.0 );
				float temp_output_47_0_g64 = clampResult1_g57;
				float3 lerpResult4_g66 = lerp( ( ( temp_output_72_0_g64 * v.normal ) * ( _DeformationStrength / 100.0 ) ) , float3( 0,0,0 ) , temp_output_47_0_g64);
				
				o.ase_texcoord8.xy = v.ase_texcoord.xy;
				o.ase_texcoord9 = v.vertex;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord8.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( v.vertex.xyz + lerpResult4_g66 );
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.vertex.w = 1;
				v.normal = v.normal;
				v.tangent = float4( v.tangent.xyz , 0.0 );

				o.pos = UnityObjectToClipPos(v.vertex);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
				o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				#ifdef DYNAMICLIGHTMAP_ON
					o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#else
					o.lmap.zw = 0;
				#endif
				#ifdef LIGHTMAP_ON
					o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
					#ifdef DIRLIGHTMAP_OFF
						o.lmapFadePos.xyz = (mul(unity_ObjectToWorld, v.vertex).xyz - unity_ShadowFadeCenterAndType.xyz) * unity_ShadowFadeCenterAndType.w;
						o.lmapFadePos.w = (-UnityObjectToViewPos(v.vertex).z) * (1.0 - unity_ShadowFadeCenterAndType.w);
					#endif
				#else
					o.lmap.xy = 0;
					#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
						o.sh = 0;
						o.sh = ShadeSHPerVertex (worldNormal, o.sh);
					#endif
				#endif
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( appdata v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				appdata o = (appdata) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
				o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			v2f vert ( appdata v )
			{
				return VertexFunction( v );
			}
			#endif

			void frag (v2f IN 
				, out half4 outGBuffer0 : SV_Target0
				, out half4 outGBuffer1 : SV_Target1
				, out half4 outGBuffer2 : SV_Target2
				, out half4 outEmission : SV_Target3
				#if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
				, out half4 outShadowMask : SV_Target4
				#endif
				#ifdef _DEPTHOFFSET_ON
				, out float outputDepth : SV_Depth
				#endif
			) 
			{
				UNITY_SETUP_INSTANCE_ID(IN);

				#ifdef LOD_FADE_CROSSFADE
					UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
				#endif

				#if defined(_SPECULAR_SETUP)
					SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
				#else
					SurfaceOutputStandard o = (SurfaceOutputStandard)0;
				#endif
				float3 WorldTangent = float3(IN.tSpace0.x,IN.tSpace1.x,IN.tSpace2.x);
				float3 WorldBiTangent = float3(IN.tSpace0.y,IN.tSpace1.y,IN.tSpace2.y);
				float3 WorldNormal = float3(IN.tSpace0.z,IN.tSpace1.z,IN.tSpace2.z);
				float3 worldPos = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				half atten = 1;

				float2 uv_Albedo = IN.ase_texcoord8.xy * _Albedo_ST.xy + _Albedo_ST.zw;
				float4 temp_output_1_0_g50 = ( _BaseColor * tex2D( _Albedo, uv_Albedo ) );
				float3 break8_g67 = ( IN.ase_texcoord9.xyz / ( _CellDivisionAmount / 100.0 ) );
				float mulTime15_g67 = _Time.y * _ScaleTime;
				float temp_output_13_0_g67 = ( frac( ( sin( mulTime15_g67 ) * ( 53270.0 + 0.0 ) ) ) * _NoiseSpeed );
				float4 appendResult10_g67 = (float4(( break8_g67.x + temp_output_13_0_g67 ) , ( break8_g67.y + temp_output_13_0_g67 ) , ( break8_g67.z + temp_output_13_0_g67 ) , 0.0));
				float3 temp_output_13_0_g69 = ceil( appendResult10_g67 ).xyz;
				float dotResult12_g69 = dot( temp_output_13_0_g69 , float3(15400,28700,38700) );
				float dotResult15_g69 = dot( temp_output_13_0_g69 , float3(35300,51700,79500) );
				float dotResult17_g69 = dot( temp_output_13_0_g69 , float3(49700,20800,73000) );
				float3 appendResult11_g69 = (float3(dotResult12_g69 , dotResult15_g69 , dotResult17_g69));
				float3 temp_cast_2 = (1.0).xxx;
				float3 temp_output_72_0_g64 = (float3( 0,0,0 ) + (( ( frac( ( sin( appendResult11_g69 ) * ( 42940.0 + 0.0 ) ) ) * 2.0 ) - temp_cast_2 ) - float3( -1,-1,-1 )) * (float3( 1,1,1 ) - float3( 0,0,0 )) / (float3( 1,1,1 ) - float3( -1,-1,-1 )));
				float3 clampResult30_g64 = clamp( pow( temp_output_72_0_g64 , float3(4,4,4) ) , float3( 0,0,0 ) , float3( 1,1,1 ) );
				float3 break27_g57 = _BlendAxis;
				float3 break24_g57 = IN.ase_texcoord9.xyz;
				float mulTime17_g57 = _Time.y * _ScaleTime;
				float temp_output_6_0_g57 = ( ( ( break27_g57.x == 1.0 ? break24_g57.x : ( break27_g57.y == 1.0 ? break24_g57.y : break24_g57.z ) ) + _BandCenterlength ) - ( _BandAxislength * (( _UseFillPercent )?( _Fillpercentage ):( (0.0 + (sin( ( _BandSpeed * mulTime17_g57 ) ) - -1.0) * (1.0 - 0.0) / (1.0 - -1.0)) )) ) );
				float smoothstepResult2_g57 = smoothstep( 0.0 , 1.0 , ( distance( temp_output_6_0_g57 , 0.0 ) / _BandTransitionLength ));
				float clampResult1_g57 = clamp( smoothstepResult2_g57 , 0.0 , 1.0 );
				float temp_output_47_0_g64 = clampResult1_g57;
				float4 lerpResult6_g65 = lerp( ( float4( ( clampResult30_g64 * float3(10,10,10) ) , 0.0 ) * _GlitchEmissionColor ) , _BaseColor , temp_output_47_0_g64);
				float4 temp_cast_6 = (1.0).xxxx;
				float4 lerpResult7_g50 = lerp( temp_output_1_0_g50 , ( ( temp_output_1_0_g50 + lerpResult6_g65 ) - temp_cast_6 ) , 1.0);
				
				float2 uv_Normal = IN.ase_texcoord8.xy * _Normal_ST.xy + _Normal_ST.zw;
				float4 tex2DNode46 = tex2D( _Normal, uv_Normal );
				
				float2 uv_MetallicMap = IN.ase_texcoord8.xy * _MetallicMap_ST.xy + _MetallicMap_ST.zw;
				
				float temp_output_94_8 = temp_output_6_0_g57;
				float clampResult8_g64 = clamp( ( (( _InvertAlpha )?( temp_output_94_8 ):( ( 1.0 - temp_output_94_8 ) )) - ( temp_output_72_0_g64.x * 0.02 ) ) , 0.0 , 1.0 );
				
				o.Albedo = lerpResult7_g50.xyz;
				o.Normal = tex2DNode46.rgb;
				o.Emission = _Emission.rgb;
				#if defined(_SPECULAR_SETUP)
					o.Specular = fixed3( 0, 0, 0 );
				#else
					o.Metallic = ( tex2D( _MetallicMap, uv_MetallicMap ) * _MetallicStrength ).r;
				#endif
				o.Smoothness = _Smoothness;
				o.Occlusion = _Occlusion;
				o.Alpha = _Alpha;
				float AlphaClipThreshold = (( _AlphaClipping )?( (1.0 + (clampResult8_g64 - 0.0) * (2.0 - 1.0) / (1.0 - 0.0)) ):( 1.0 ));
				float3 BakedGI = 0;

				#ifdef _ALPHATEST_ON
					clip( o.Alpha - AlphaClipThreshold );
				#endif

				#ifdef _DEPTHOFFSET_ON
					outputDepth = IN.pos.z;
				#endif

				#ifndef USING_DIRECTIONAL_LIGHT
					fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				#else
					fixed3 lightDir = _WorldSpaceLightPos0.xyz;
				#endif

				float3 worldN;
				worldN.x = dot(IN.tSpace0.xyz, o.Normal);
				worldN.y = dot(IN.tSpace1.xyz, o.Normal);
				worldN.z = dot(IN.tSpace2.xyz, o.Normal);
				worldN = normalize(worldN);
				o.Normal = worldN;

				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
				gi.indirect.diffuse = 0;
				gi.indirect.specular = 0;
				gi.light.color = 0;
				gi.light.dir = half3(0,1,0);

				UnityGIInput giInput;
				UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
				giInput.light = gi.light;
				giInput.worldPos = worldPos;
				giInput.worldViewDir = worldViewDir;
				giInput.atten = atten;
				#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
					giInput.lightmapUV = IN.lmap;
				#else
					giInput.lightmapUV = 0.0;
				#endif
				#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
					giInput.ambient = IN.sh;
				#else
					giInput.ambient.rgb = 0.0;
				#endif
				giInput.probeHDR[0] = unity_SpecCube0_HDR;
				giInput.probeHDR[1] = unity_SpecCube1_HDR;
				#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
					giInput.boxMin[0] = unity_SpecCube0_BoxMin;
				#endif
				#ifdef UNITY_SPECCUBE_BOX_PROJECTION
					giInput.boxMax[0] = unity_SpecCube0_BoxMax;
					giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
					giInput.boxMax[1] = unity_SpecCube1_BoxMax;
					giInput.boxMin[1] = unity_SpecCube1_BoxMin;
					giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
				#endif

				#if defined(_SPECULAR_SETUP)
					LightingStandardSpecular_GI( o, giInput, gi );
				#else
					LightingStandard_GI( o, giInput, gi );
				#endif

				#ifdef ASE_BAKEDGI
					gi.indirect.diffuse = BakedGI;
				#endif

				#if UNITY_SHOULD_SAMPLE_SH && !defined(LIGHTMAP_ON) && defined(ASE_NO_AMBIENT)
					gi.indirect.diffuse = 0;
				#endif

				#if defined(_SPECULAR_SETUP)
					outEmission = LightingStandardSpecular_Deferred( o, worldViewDir, gi, outGBuffer0, outGBuffer1, outGBuffer2 );
				#else
					outEmission = LightingStandard_Deferred( o, worldViewDir, gi, outGBuffer0, outGBuffer1, outGBuffer2 );
				#endif

				#if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
					outShadowMask = UnityGetRawBakedOcclusions (IN.lmap.xy, float3(0, 0, 0));
				#endif
				#ifndef UNITY_HDR_ON
					outEmission.rgb = exp2(-outEmission.rgb);
				#endif
			}
			ENDCG
		}

		
		Pass
		{
			
			Name "Meta"
			Tags { "LightMode"="Meta" }
			Cull Off

			CGPROGRAM
			#define _ALPHABLEND_ON 1
			#define UNITY_STANDARD_USE_DITHER_MASK 1
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#pragma multi_compile_instancing
			#pragma multi_compile __ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _ALPHATEST_ON 1

			#pragma vertex vert
			#pragma fragment frag
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#pragma shader_feature EDITOR_VISUALIZATION
			#ifndef UNITY_PASS_META
				#define UNITY_PASS_META
			#endif
			#include "HLSLSupport.cginc"
			#if !defined( UNITY_INSTANCED_LOD_FADE )
				#define UNITY_INSTANCED_LOD_FADE
			#endif
			#if !defined( UNITY_INSTANCED_SH )
				#define UNITY_INSTANCED_SH
			#endif
			#if !defined( UNITY_INSTANCED_LIGHTMAPSTS )
				#define UNITY_INSTANCED_LIGHTMAPSTS
			#endif
			#include "UnityShaderVariables.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			#include "UnityMetaPass.cginc"

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_TANGENT
			#define ASE_NEEDS_FRAG_POSITION

			struct appdata {
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			struct v2f {
				#if UNITY_VERSION >= 201810
					UNITY_POSITION(pos);
				#else
					float4 pos : SV_POSITION;
				#endif
				#ifdef EDITOR_VISUALIZATION
					float2 vizUV : TEXCOORD1;
					float4 lightCoord : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			uniform float _CellDivisionAmount;
			uniform float _ScaleTime;
			uniform float _NoiseSpeed;
			uniform float _DeformationStrength;
			uniform float3 _BlendAxis;
			uniform float _BandCenterlength;
			uniform float _BandAxislength;
			uniform float _UseFillPercent;
			uniform float _BandSpeed;
			uniform float _Fillpercentage;
			uniform float _BandTransitionLength;
			uniform float4 _BaseColor;
			uniform sampler2D _Albedo;
			uniform float4 _Albedo_ST;
			uniform float4 _GlitchEmissionColor;
			uniform float4 _Emission;
			uniform float _Alpha;
			uniform float _AlphaClipping;
			uniform float _InvertAlpha;

	
			
			v2f VertexFunction (appdata v  ) {
				UNITY_SETUP_INSTANCE_ID(v);
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				UNITY_TRANSFER_INSTANCE_ID(v,o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 break8_g67 = ( v.vertex.xyz / ( _CellDivisionAmount / 100.0 ) );
				float mulTime15_g67 = _Time.y * _ScaleTime;
				float temp_output_13_0_g67 = ( frac( ( sin( mulTime15_g67 ) * ( 53270.0 + 0.0 ) ) ) * _NoiseSpeed );
				float4 appendResult10_g67 = (float4(( break8_g67.x + temp_output_13_0_g67 ) , ( break8_g67.y + temp_output_13_0_g67 ) , ( break8_g67.z + temp_output_13_0_g67 ) , 0.0));
				float3 temp_output_13_0_g69 = ceil( appendResult10_g67 ).xyz;
				float dotResult12_g69 = dot( temp_output_13_0_g69 , float3(15400,28700,38700) );
				float dotResult15_g69 = dot( temp_output_13_0_g69 , float3(35300,51700,79500) );
				float dotResult17_g69 = dot( temp_output_13_0_g69 , float3(49700,20800,73000) );
				float3 appendResult11_g69 = (float3(dotResult12_g69 , dotResult15_g69 , dotResult17_g69));
				float3 temp_cast_1 = (1.0).xxx;
				float3 temp_output_72_0_g64 = (float3( 0,0,0 ) + (( ( frac( ( sin( appendResult11_g69 ) * ( 42940.0 + 0.0 ) ) ) * 2.0 ) - temp_cast_1 ) - float3( -1,-1,-1 )) * (float3( 1,1,1 ) - float3( 0,0,0 )) / (float3( 1,1,1 ) - float3( -1,-1,-1 )));
				float3 break27_g57 = _BlendAxis;
				float3 break24_g57 = v.vertex.xyz;
				float mulTime17_g57 = _Time.y * _ScaleTime;
				float temp_output_6_0_g57 = ( ( ( break27_g57.x == 1.0 ? break24_g57.x : ( break27_g57.y == 1.0 ? break24_g57.y : break24_g57.z ) ) + _BandCenterlength ) - ( _BandAxislength * (( _UseFillPercent )?( _Fillpercentage ):( (0.0 + (sin( ( _BandSpeed * mulTime17_g57 ) ) - -1.0) * (1.0 - 0.0) / (1.0 - -1.0)) )) ) );
				float smoothstepResult2_g57 = smoothstep( 0.0 , 1.0 , ( distance( temp_output_6_0_g57 , 0.0 ) / _BandTransitionLength ));
				float clampResult1_g57 = clamp( smoothstepResult2_g57 , 0.0 , 1.0 );
				float temp_output_47_0_g64 = clampResult1_g57;
				float3 lerpResult4_g66 = lerp( ( ( temp_output_72_0_g64 * v.normal ) * ( _DeformationStrength / 100.0 ) ) , float3( 0,0,0 ) , temp_output_47_0_g64);
				
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				o.ase_texcoord4 = v.vertex;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( v.vertex.xyz + lerpResult4_g66 );
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.vertex.w = 1;
				v.normal = v.normal;
				v.tangent = float4( v.tangent.xyz , 0.0 );

				#ifdef EDITOR_VISUALIZATION
					o.vizUV = 0;
					o.lightCoord = 0;
					if (unity_VisualizationMode == EDITORVIZ_TEXTURE)
						o.vizUV = UnityMetaVizUV(unity_EditorViz_UVIndex, v.texcoord.xy, v.texcoord1.xy, v.texcoord2.xy, unity_EditorViz_Texture_ST);
					else if (unity_VisualizationMode == EDITORVIZ_SHOWLIGHTMASK)
					{
						o.vizUV = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
						o.lightCoord = mul(unity_EditorViz_WorldToLight, mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)));
					}
				#endif

				o.pos = UnityMetaVertexPosition(v.vertex, v.texcoord1.xy, v.texcoord2.xy, unity_LightmapST, unity_DynamicLightmapST);

				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( appdata v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				appdata o = (appdata) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
				o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			v2f vert ( appdata v )
			{
				return VertexFunction( v );
			}
			#endif

			fixed4 frag (v2f IN 
				#ifdef _DEPTHOFFSET_ON
				, out float outputDepth : SV_Depth
				#endif
				) : SV_Target 
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				
				#ifdef LOD_FADE_CROSSFADE
					UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
				#endif

				#if defined(_SPECULAR_SETUP)
					SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
				#else
					SurfaceOutputStandard o = (SurfaceOutputStandard)0;
				#endif
				
				float2 uv_Albedo = IN.ase_texcoord3.xy * _Albedo_ST.xy + _Albedo_ST.zw;
				float4 temp_output_1_0_g50 = ( _BaseColor * tex2D( _Albedo, uv_Albedo ) );
				float3 break8_g67 = ( IN.ase_texcoord4.xyz / ( _CellDivisionAmount / 100.0 ) );
				float mulTime15_g67 = _Time.y * _ScaleTime;
				float temp_output_13_0_g67 = ( frac( ( sin( mulTime15_g67 ) * ( 53270.0 + 0.0 ) ) ) * _NoiseSpeed );
				float4 appendResult10_g67 = (float4(( break8_g67.x + temp_output_13_0_g67 ) , ( break8_g67.y + temp_output_13_0_g67 ) , ( break8_g67.z + temp_output_13_0_g67 ) , 0.0));
				float3 temp_output_13_0_g69 = ceil( appendResult10_g67 ).xyz;
				float dotResult12_g69 = dot( temp_output_13_0_g69 , float3(15400,28700,38700) );
				float dotResult15_g69 = dot( temp_output_13_0_g69 , float3(35300,51700,79500) );
				float dotResult17_g69 = dot( temp_output_13_0_g69 , float3(49700,20800,73000) );
				float3 appendResult11_g69 = (float3(dotResult12_g69 , dotResult15_g69 , dotResult17_g69));
				float3 temp_cast_2 = (1.0).xxx;
				float3 temp_output_72_0_g64 = (float3( 0,0,0 ) + (( ( frac( ( sin( appendResult11_g69 ) * ( 42940.0 + 0.0 ) ) ) * 2.0 ) - temp_cast_2 ) - float3( -1,-1,-1 )) * (float3( 1,1,1 ) - float3( 0,0,0 )) / (float3( 1,1,1 ) - float3( -1,-1,-1 )));
				float3 clampResult30_g64 = clamp( pow( temp_output_72_0_g64 , float3(4,4,4) ) , float3( 0,0,0 ) , float3( 1,1,1 ) );
				float3 break27_g57 = _BlendAxis;
				float3 break24_g57 = IN.ase_texcoord4.xyz;
				float mulTime17_g57 = _Time.y * _ScaleTime;
				float temp_output_6_0_g57 = ( ( ( break27_g57.x == 1.0 ? break24_g57.x : ( break27_g57.y == 1.0 ? break24_g57.y : break24_g57.z ) ) + _BandCenterlength ) - ( _BandAxislength * (( _UseFillPercent )?( _Fillpercentage ):( (0.0 + (sin( ( _BandSpeed * mulTime17_g57 ) ) - -1.0) * (1.0 - 0.0) / (1.0 - -1.0)) )) ) );
				float smoothstepResult2_g57 = smoothstep( 0.0 , 1.0 , ( distance( temp_output_6_0_g57 , 0.0 ) / _BandTransitionLength ));
				float clampResult1_g57 = clamp( smoothstepResult2_g57 , 0.0 , 1.0 );
				float temp_output_47_0_g64 = clampResult1_g57;
				float4 lerpResult6_g65 = lerp( ( float4( ( clampResult30_g64 * float3(10,10,10) ) , 0.0 ) * _GlitchEmissionColor ) , _BaseColor , temp_output_47_0_g64);
				float4 temp_cast_6 = (1.0).xxxx;
				float4 lerpResult7_g50 = lerp( temp_output_1_0_g50 , ( ( temp_output_1_0_g50 + lerpResult6_g65 ) - temp_cast_6 ) , 1.0);
				
				float temp_output_94_8 = temp_output_6_0_g57;
				float clampResult8_g64 = clamp( ( (( _InvertAlpha )?( temp_output_94_8 ):( ( 1.0 - temp_output_94_8 ) )) - ( temp_output_72_0_g64.x * 0.02 ) ) , 0.0 , 1.0 );
				
				o.Albedo = lerpResult7_g50.xyz;
				o.Normal = fixed3( 0, 0, 1 );
				o.Emission = _Emission.rgb;
				o.Alpha = _Alpha;
				float AlphaClipThreshold = (( _AlphaClipping )?( (1.0 + (clampResult8_g64 - 0.0) * (2.0 - 1.0) / (1.0 - 0.0)) ):( 1.0 ));

				#ifdef _ALPHATEST_ON
					clip( o.Alpha - AlphaClipThreshold );
				#endif

				#ifdef _DEPTHOFFSET_ON
					outputDepth = IN.pos.z;
				#endif

				UnityMetaInput metaIN;
				UNITY_INITIALIZE_OUTPUT(UnityMetaInput, metaIN);
				metaIN.Albedo = o.Albedo;
				metaIN.Emission = o.Emission;
				#ifdef EDITOR_VISUALIZATION
					metaIN.VizUV = IN.vizUV;
					metaIN.LightCoord = IN.lightCoord;
				#endif
				return UnityMetaFragment(metaIN);
			}
			ENDCG
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }
			ZWrite On
			ZTest LEqual
			AlphaToMask Off

			CGPROGRAM
			#define _ALPHABLEND_ON 1
			#define UNITY_STANDARD_USE_DITHER_MASK 1
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#pragma multi_compile_instancing
			#pragma multi_compile __ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _ALPHATEST_ON 1

			#pragma vertex vert
			#pragma fragment frag
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#pragma multi_compile_shadowcaster
			#ifndef UNITY_PASS_SHADOWCASTER
				#define UNITY_PASS_SHADOWCASTER
			#endif
			#include "HLSLSupport.cginc"
			#ifndef UNITY_INSTANCED_LOD_FADE
				#define UNITY_INSTANCED_LOD_FADE
			#endif
			#ifndef UNITY_INSTANCED_SH
				#define UNITY_INSTANCED_SH
			#endif
			#ifndef UNITY_INSTANCED_LIGHTMAPSTS
				#define UNITY_INSTANCED_LIGHTMAPSTS
			#endif
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityShaderVariables.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_TANGENT
			#define ASE_NEEDS_FRAG_POSITION

			struct appdata {
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f {
				V2F_SHADOW_CASTER;
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#ifdef UNITY_STANDARD_USE_DITHER_MASK
				sampler3D _DitherMaskLOD;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			uniform float _CellDivisionAmount;
			uniform float _ScaleTime;
			uniform float _NoiseSpeed;
			uniform float _DeformationStrength;
			uniform float3 _BlendAxis;
			uniform float _BandCenterlength;
			uniform float _BandAxislength;
			uniform float _UseFillPercent;
			uniform float _BandSpeed;
			uniform float _Fillpercentage;
			uniform float _BandTransitionLength;
			uniform float _Alpha;
			uniform float _AlphaClipping;
			uniform float _InvertAlpha;

	
			
			v2f VertexFunction (appdata v  ) {
				UNITY_SETUP_INSTANCE_ID(v);
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				UNITY_TRANSFER_INSTANCE_ID(v,o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 break8_g67 = ( v.vertex.xyz / ( _CellDivisionAmount / 100.0 ) );
				float mulTime15_g67 = _Time.y * _ScaleTime;
				float temp_output_13_0_g67 = ( frac( ( sin( mulTime15_g67 ) * ( 53270.0 + 0.0 ) ) ) * _NoiseSpeed );
				float4 appendResult10_g67 = (float4(( break8_g67.x + temp_output_13_0_g67 ) , ( break8_g67.y + temp_output_13_0_g67 ) , ( break8_g67.z + temp_output_13_0_g67 ) , 0.0));
				float3 temp_output_13_0_g69 = ceil( appendResult10_g67 ).xyz;
				float dotResult12_g69 = dot( temp_output_13_0_g69 , float3(15400,28700,38700) );
				float dotResult15_g69 = dot( temp_output_13_0_g69 , float3(35300,51700,79500) );
				float dotResult17_g69 = dot( temp_output_13_0_g69 , float3(49700,20800,73000) );
				float3 appendResult11_g69 = (float3(dotResult12_g69 , dotResult15_g69 , dotResult17_g69));
				float3 temp_cast_1 = (1.0).xxx;
				float3 temp_output_72_0_g64 = (float3( 0,0,0 ) + (( ( frac( ( sin( appendResult11_g69 ) * ( 42940.0 + 0.0 ) ) ) * 2.0 ) - temp_cast_1 ) - float3( -1,-1,-1 )) * (float3( 1,1,1 ) - float3( 0,0,0 )) / (float3( 1,1,1 ) - float3( -1,-1,-1 )));
				float3 break27_g57 = _BlendAxis;
				float3 break24_g57 = v.vertex.xyz;
				float mulTime17_g57 = _Time.y * _ScaleTime;
				float temp_output_6_0_g57 = ( ( ( break27_g57.x == 1.0 ? break24_g57.x : ( break27_g57.y == 1.0 ? break24_g57.y : break24_g57.z ) ) + _BandCenterlength ) - ( _BandAxislength * (( _UseFillPercent )?( _Fillpercentage ):( (0.0 + (sin( ( _BandSpeed * mulTime17_g57 ) ) - -1.0) * (1.0 - 0.0) / (1.0 - -1.0)) )) ) );
				float smoothstepResult2_g57 = smoothstep( 0.0 , 1.0 , ( distance( temp_output_6_0_g57 , 0.0 ) / _BandTransitionLength ));
				float clampResult1_g57 = clamp( smoothstepResult2_g57 , 0.0 , 1.0 );
				float temp_output_47_0_g64 = clampResult1_g57;
				float3 lerpResult4_g66 = lerp( ( ( temp_output_72_0_g64 * v.normal ) * ( _DeformationStrength / 100.0 ) ) , float3( 0,0,0 ) , temp_output_47_0_g64);
				
				o.ase_texcoord2 = v.vertex;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( v.vertex.xyz + lerpResult4_g66 );
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.vertex.w = 1;
				v.normal = v.normal;
				v.tangent = float4( v.tangent.xyz , 0.0 );

				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( appdata v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				appdata o = (appdata) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
				o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			v2f vert ( appdata v )
			{
				return VertexFunction( v );
			}
			#endif

			fixed4 frag (v2f IN 
				#ifdef _DEPTHOFFSET_ON
				, out float outputDepth : SV_Depth
				#endif
				#if !defined( CAN_SKIP_VPOS )
				, UNITY_VPOS_TYPE vpos : VPOS
				#endif
				) : SV_Target 
			{
				UNITY_SETUP_INSTANCE_ID(IN);

				#ifdef LOD_FADE_CROSSFADE
					UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
				#endif

				#if defined(_SPECULAR_SETUP)
					SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
				#else
					SurfaceOutputStandard o = (SurfaceOutputStandard)0;
				#endif

				float3 break27_g57 = _BlendAxis;
				float3 break24_g57 = IN.ase_texcoord2.xyz;
				float mulTime17_g57 = _Time.y * _ScaleTime;
				float temp_output_6_0_g57 = ( ( ( break27_g57.x == 1.0 ? break24_g57.x : ( break27_g57.y == 1.0 ? break24_g57.y : break24_g57.z ) ) + _BandCenterlength ) - ( _BandAxislength * (( _UseFillPercent )?( _Fillpercentage ):( (0.0 + (sin( ( _BandSpeed * mulTime17_g57 ) ) - -1.0) * (1.0 - 0.0) / (1.0 - -1.0)) )) ) );
				float temp_output_94_8 = temp_output_6_0_g57;
				float3 break8_g67 = ( IN.ase_texcoord2.xyz / ( _CellDivisionAmount / 100.0 ) );
				float mulTime15_g67 = _Time.y * _ScaleTime;
				float temp_output_13_0_g67 = ( frac( ( sin( mulTime15_g67 ) * ( 53270.0 + 0.0 ) ) ) * _NoiseSpeed );
				float4 appendResult10_g67 = (float4(( break8_g67.x + temp_output_13_0_g67 ) , ( break8_g67.y + temp_output_13_0_g67 ) , ( break8_g67.z + temp_output_13_0_g67 ) , 0.0));
				float3 temp_output_13_0_g69 = ceil( appendResult10_g67 ).xyz;
				float dotResult12_g69 = dot( temp_output_13_0_g69 , float3(15400,28700,38700) );
				float dotResult15_g69 = dot( temp_output_13_0_g69 , float3(35300,51700,79500) );
				float dotResult17_g69 = dot( temp_output_13_0_g69 , float3(49700,20800,73000) );
				float3 appendResult11_g69 = (float3(dotResult12_g69 , dotResult15_g69 , dotResult17_g69));
				float3 temp_cast_1 = (1.0).xxx;
				float3 temp_output_72_0_g64 = (float3( 0,0,0 ) + (( ( frac( ( sin( appendResult11_g69 ) * ( 42940.0 + 0.0 ) ) ) * 2.0 ) - temp_cast_1 ) - float3( -1,-1,-1 )) * (float3( 1,1,1 ) - float3( 0,0,0 )) / (float3( 1,1,1 ) - float3( -1,-1,-1 )));
				float clampResult8_g64 = clamp( ( (( _InvertAlpha )?( temp_output_94_8 ):( ( 1.0 - temp_output_94_8 ) )) - ( temp_output_72_0_g64.x * 0.02 ) ) , 0.0 , 1.0 );
				
				o.Normal = fixed3( 0, 0, 1 );
				o.Occlusion = 1;
				o.Alpha = _Alpha;
				float AlphaClipThreshold = (( _AlphaClipping )?( (1.0 + (clampResult8_g64 - 0.0) * (2.0 - 1.0) / (1.0 - 0.0)) ):( 1.0 ));
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_SHADOW_ON
					if (unity_LightShadowBias.z != 0.0)
						clip(o.Alpha - AlphaClipThresholdShadow);
					#ifdef _ALPHATEST_ON
					else
						clip(o.Alpha - AlphaClipThreshold);
					#endif
				#else
					#ifdef _ALPHATEST_ON
						clip(o.Alpha - AlphaClipThreshold);
					#endif
				#endif

				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif

				#ifdef UNITY_STANDARD_USE_DITHER_MASK
					half alphaRef = tex3D(_DitherMaskLOD, float3(vpos.xy*0.25,o.Alpha*0.9375)).a;
					clip(alphaRef - 0.01);
				#endif

				#ifdef _DEPTHOFFSET_ON
					outputDepth = IN.pos.z;
				#endif

				SHADOW_CASTER_FRAGMENT(IN)
			}
			ENDCG
		}
		
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18500
294;73;1348;432;3747.35;182.6686;1;True;False
Node;AmplifyShaderEditor.RangedFloatNode;39;-3373.48,-384.7328;Inherit;False;Property;_ScaleTime;Scale Time;0;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PosVertexDataNode;35;-3831.072,-345.196;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;43;-3761.257,246.4619;Inherit;False;Property;_BandTransitionLength;Band Transition Length;22;0;Create;True;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;40;-3440.214,68.17511;Inherit;False;Property;_BandSpeed;Band Speed;19;0;Create;True;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;41;-3410.712,-29.53815;Inherit;False;Property;_Fillpercentage;Fill percentage;25;0;Create;True;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;36;-3411.257,304.4619;Inherit;False;Property;_BlendAxis;BlendAxis;21;0;Create;True;0;0;False;0;False;1,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;42;-3718.257,118.4619;Inherit;False;Property;_BandAxislength;Band Axis length;20;0;Create;True;0;0;False;0;False;2;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;37;-3415.257,212.4619;Inherit;False;Property;_BandCenterlength;Band Center length;17;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;94;-2993.03,129.4317;Inherit;True;MaskBand;23;;57;e2a0302d901d99b469fcf8d12c25635d;0;8;4;FLOAT;1;False;10;FLOAT;2;False;12;FLOAT;0.09;False;16;FLOAT;2;False;19;FLOAT;1;False;21;FLOAT;1;False;23;FLOAT3;0,0,0;False;26;FLOAT3;0,0,0;False;2;FLOAT;8;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;90;-2516.96,-101.9111;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;28;-2268.804,456.54;Inherit;False;Property;_CellDivisionAmount;Cell Division Amount;14;0;Create;True;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;16;-2282.88,-750.8534;Inherit;False;Property;_BaseColor;BaseColor;2;0;Create;True;0;0;False;0;False;1,1,1,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;26;-2235.969,200.2473;Inherit;False;Property;_NoiseSpeed;NoiseSpeed;16;0;Create;True;0;0;False;0;False;15;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;25;-2239.746,-495.3286;Inherit;False;Property;_GlitchEmissionColor;GlitchEmissionColor;18;1;[HDR];Create;True;0;0;False;0;False;1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;27;-2257.135,332.5279;Inherit;False;Property;_DeformationStrength;DeformationStrength;15;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;34;-2290.414,-100.9981;Inherit;True;Property;_InvertAlpha;Invert Alpha;11;0;Create;True;0;0;False;0;False;1;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;46;-979.9487,622.6708;Inherit;True;Property;_Normal;Normal;3;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;6;-527.5229,452.6378;Inherit;False;Property;_Alpha;Alpha;10;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;11;-713.7925,158.906;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;10;-1134.079,139.8134;Inherit;True;Property;_MetallicMap;Metallic Map;5;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TangentVertexDataNode;70;-224.2666,544.8022;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NormalVertexDataNode;69;-220.2666,389.8022;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;12;-1067.74,398.2974;Inherit;False;Property;_MetallicStrength;Metallic Strength;6;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;44;-553.9467,750.0482;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;17;-1410.846,-458.0857;Inherit;True;Property;_Albedo;Albedo;1;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldPosInputsNode;78;-4133.042,-144.8956;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;7;-521.6483,241.1509;Inherit;False;Property;_Smoothness;Smoothness;8;0;Create;True;0;0;False;0;False;0.5;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;45;-957.661,864.5342;Inherit;False;Property;_NormalStrength;Normal Strength;4;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;14;-961.9684,-659.355;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;92;-597.752,-491.2738;Inherit;True;BlendLinearBurn;-1;;50;17595ca3163890e4bb3cf61edf1cd490;0;3;1;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT;1;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;8;-527.5228,345.4257;Inherit;False;Property;_Occlusion;Occlusion;7;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;96;-1697.064,-34.06866;Inherit;True;Glitch;12;;64;398259ea3a839cb4d894dac9367a6fef;0;8;56;FLOAT;1;False;50;COLOR;1,1,1,1;False;49;FLOAT;0;False;47;FLOAT;0.93;False;48;FLOAT;1;False;44;FLOAT;0.04;False;45;FLOAT;5;False;46;COLOR;1,1,1,0;False;3;FLOAT3;35;FLOAT;21;FLOAT4;0
Node;AmplifyShaderEditor.WorldToObjectTransfNode;79;-3914.716,-141.1697;Inherit;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;82;-3693.4,-118.42;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;9;-748.2657,-144.903;Inherit;False;Property;_Emission;Emission;9;1;[HDR];Create;True;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;ASEMaterialInspector;0;10;New Amplify Shader;ed95fe726fd7b4644bb42f4d1ddd2bcd;True;Meta;0;4;Meta;0;True;0;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;False;True;3;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;DisableBatching=False=DisableBatching;True;2;0;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;ASEMaterialInspector;0;10;New Amplify Shader;ed95fe726fd7b4644bb42f4d1ddd2bcd;True;ForwardAdd;0;2;ForwardAdd;0;True;0;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;False;True;3;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;DisableBatching=False=DisableBatching;True;2;0;True;4;5;False;-1;1;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;True;1;LightMode=ForwardAdd;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;5;0,0;Float;False;False;-1;2;ASEMaterialInspector;0;10;New Amplify Shader;ed95fe726fd7b4644bb42f4d1ddd2bcd;True;ShadowCaster;0;5;ShadowCaster;0;True;0;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;False;True;3;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;DisableBatching=False=DisableBatching;True;2;0;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;0,0;Float;False;True;-1;2;ASEMaterialInspector;0;10;BandGlitchLit;ed95fe726fd7b4644bb42f4d1ddd2bcd;True;ForwardBase;0;1;ForwardBase;18;True;0;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;2;False;-1;True;3;False;-1;False;True;3;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;DisableBatching=False=DisableBatching;True;4;0;True;1;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;0;Standard;40;Workflow,InvertActionOnDeselection;1;Surface;1;  Blend;0;  Refraction Model;0;  Dither Shadows;1;Two Sided;1;Deferred Pass;1;Transmission;0;  Transmission Shadow;0.5,False,-1;Translucency;0;  Translucency Strength;1,False,-1;  Normal Distortion;0.5,False,-1;  Scattering;2,False,-1;  Direct;0.9,False,-1;  Ambient;0.1,False,-1;  Shadow;0.5,False,-1;Cast Shadows;1;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;1;LOD CrossFade;1;Built-in Fog;1;Ambient Light;1;Meta Pass;1;Add Pass;1;Override Baked GI;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Fwd Specular Highlights Toggle;0;Fwd Reflections Toggle;0;Disable Batching;0;Vertex Position,InvertActionOnDeselection;1;0;6;False;True;True;True;True;True;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;ASEMaterialInspector;0;10;New Amplify Shader;ed95fe726fd7b4644bb42f4d1ddd2bcd;True;Deferred;0;3;Deferred;0;True;0;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;False;True;3;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;DisableBatching=False=DisableBatching;True;2;0;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;LightMode=Deferred;True;2;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;0,0;Float;False;False;-1;2;ASEMaterialInspector;0;10;New Amplify Shader;ed95fe726fd7b4644bb42f4d1ddd2bcd;True;ExtraPrePass;0;0;ExtraPrePass;6;True;0;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;False;True;3;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;DisableBatching=False=DisableBatching;True;2;0;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;True;0;False;-1;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=ForwardBase;False;0;;0;0;Standard;0;False;0
WireConnection;94;4;43;0
WireConnection;94;10;42;0
WireConnection;94;12;41;0
WireConnection;94;16;40;0
WireConnection;94;19;39;0
WireConnection;94;21;37;0
WireConnection;94;23;35;0
WireConnection;94;26;36;0
WireConnection;90;0;94;8
WireConnection;34;0;90;0
WireConnection;34;1;94;8
WireConnection;11;0;10;0
WireConnection;11;1;12;0
WireConnection;44;0;46;0
WireConnection;44;1;45;0
WireConnection;14;0;16;0
WireConnection;14;1;17;0
WireConnection;92;1;14;0
WireConnection;92;2;96;0
WireConnection;96;56;39;0
WireConnection;96;50;16;0
WireConnection;96;49;34;0
WireConnection;96;47;94;0
WireConnection;96;48;27;0
WireConnection;96;44;28;0
WireConnection;96;45;26;0
WireConnection;96;46;25;0
WireConnection;79;0;78;0
WireConnection;82;0;79;1
WireConnection;82;1;79;2
WireConnection;82;2;79;3
WireConnection;1;0;92;0
WireConnection;1;1;46;0
WireConnection;1;2;9;0
WireConnection;1;4;11;0
WireConnection;1;5;7;0
WireConnection;1;6;8;0
WireConnection;1;7;6;0
WireConnection;1;8;96;21
WireConnection;1;15;96;35
WireConnection;1;16;69;0
WireConnection;1;17;70;0
ASEEND*/
//CHKSM=000790A99DD7DD3A2BE9476FB57721615E4F594D