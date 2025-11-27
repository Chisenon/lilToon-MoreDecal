#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

namespace lilToon
{
    public class lilNoneInspector : lilToonInspector
    {
        // Decal Count
        MaterialProperty decalCount;
        
        // Decal properties arrays (max 10 decals)
        private const int MAX_DECALS = 10;
        MaterialProperty[] useDecal = new MaterialProperty[MAX_DECALS];
        MaterialProperty[] decalColor = new MaterialProperty[MAX_DECALS];
        MaterialProperty[] decalTex = new MaterialProperty[MAX_DECALS];
        MaterialProperty[] decalTex_ST = new MaterialProperty[MAX_DECALS];
        MaterialProperty[] decalTex_SR = new MaterialProperty[MAX_DECALS];
        MaterialProperty[] decalTexAngle = new MaterialProperty[MAX_DECALS];
        MaterialProperty[] decalDecalAnimation = new MaterialProperty[MAX_DECALS];
        MaterialProperty[] decalDecalSubParam = new MaterialProperty[MAX_DECALS];
        MaterialProperty[] decalIsDecal = new MaterialProperty[MAX_DECALS];
        MaterialProperty[] decalIsLeftOnly = new MaterialProperty[MAX_DECALS];
        MaterialProperty[] decalIsRightOnly = new MaterialProperty[MAX_DECALS];
        MaterialProperty[] decalShouldCopy = new MaterialProperty[MAX_DECALS];
        MaterialProperty[] decalShouldFlipMirror = new MaterialProperty[MAX_DECALS];
        MaterialProperty[] decalShouldFlipCopy = new MaterialProperty[MAX_DECALS];
        MaterialProperty[] decalBlendMode = new MaterialProperty[MAX_DECALS];
        MaterialProperty[] decalTex_UVMode = new MaterialProperty[MAX_DECALS];
        MaterialProperty[] decalSyncScale = new MaterialProperty[MAX_DECALS];

        private static bool[] isShowDecal = new bool[MAX_DECALS];
        private const string shaderName = "ChiseNote/lilNone";

        protected override void LoadCustomProperties(MaterialProperty[] props, Material material)
        {

            isCustomShader = true;

            // If you want to change rendering modes in the editor, specify the shader here
            ReplaceToCustomShaders();
            isShowRenderMode = !material.shader.name.Contains("Optional");

            // Load Decal Count
            decalCount = FindProperty("_DecalCount", props);

            // Load all decal properties (1-10)
            for(int i = 0; i < MAX_DECALS; i++)
            {
                int num = i + 1;
                useDecal[i] = FindProperty($"_UseDecal{num}", props);
                decalColor[i] = FindProperty($"_Decal{num}Color", props);
                decalTex[i] = FindProperty($"_Decal{num}Tex", props);
                decalTex_ST[i] = FindProperty($"_Decal{num}Tex_ST", props);
                decalTex_SR[i] = FindProperty($"_Decal{num}Tex_SR", props);
                decalTexAngle[i] = FindProperty($"_Decal{num}TexAngle", props);
                decalDecalAnimation[i] = FindProperty($"_Decal{num}DecalAnimation", props);
                decalDecalSubParam[i] = FindProperty($"_Decal{num}DecalSubParam", props);
                decalIsDecal[i] = FindProperty($"_Decal{num}IsDecal", props);
                decalIsLeftOnly[i] = FindProperty($"_Decal{num}IsLeftOnly", props);
                decalIsRightOnly[i] = FindProperty($"_Decal{num}IsRightOnly", props);
                decalShouldCopy[i] = FindProperty($"_Decal{num}ShouldCopy", props);
                decalShouldFlipMirror[i] = FindProperty($"_Decal{num}ShouldFlipMirror", props);
                decalShouldFlipCopy[i] = FindProperty($"_Decal{num}ShouldFlipCopy", props);
                decalBlendMode[i] = FindProperty($"_Decal{num}BlendMode", props);
                decalTex_UVMode[i] = FindProperty($"_Decal{num}Tex_UVMode", props);
                decalSyncScale[i] = FindProperty($"_Decal{num}SyncScale", props);
            }
        }

        protected override void DrawCustomProperties(Material material)
        {
            // GUIStyles Name   Description
            // ---------------- ------------------------------------
            // boxOuter         outer box
            // boxInnerHalf     inner box
            // boxInner         inner box without label
            // customBox        box (similar to unity default box)
            // customToggleFont label for box

            // Decal Count Control at Top
            EditorGUILayout.BeginVertical(boxOuter);
            EditorGUILayout.LabelField("Decal Count Control", customToggleFont);
            EditorGUILayout.BeginVertical(boxInnerHalf);
            
            EditorGUI.BeginChangeCheck();
            m_MaterialEditor.ShaderProperty(decalCount, "Decal Count (1-10)");
            if(EditorGUI.EndChangeCheck())
            {
                // Clamp value to 1-10
                decalCount.floatValue = Mathf.Clamp(decalCount.floatValue, 1, MAX_DECALS);
            }
            
            EditorGUILayout.EndVertical();
            EditorGUILayout.EndVertical();

            // Get current decal count
            int currentDecalCount = Mathf.RoundToInt(decalCount.floatValue);

            // Draw decal sections dynamically based on count
            for(int i = 0; i < currentDecalCount; i++)
            {
                int num = i + 1;
                DrawDecalSection(material, i, num);
            }
        }

        private void DrawDecalSection(Material material, int index, int displayNum)
        {
            string sectionName = $"Decal {displayNum}";
            isShowDecal[index] = Foldout(sectionName, sectionName, isShowDecal[index]);
            
            if(isShowDecal[index])
            {
                EditorGUILayout.BeginVertical(boxOuter);
                EditorGUILayout.LabelField(sectionName, customToggleFont);
                EditorGUILayout.BeginVertical(boxInnerHalf);

                m_MaterialEditor.ShaderProperty(useDecal[index], $"Use Decal {displayNum}");
                if(useDecal[index].floatValue > 0)
                {
                    EditorGUI.indentLevel++;
                    m_MaterialEditor.TexturePropertySingleLine(new GUIContent("Texture"), decalTex[index], decalColor[index]);
                    
                    // Scale同期トグル
                    m_MaterialEditor.ShaderProperty(decalSyncScale[index], "Sync Scale X/Y");
                    
                    // 同期モード時：カスタムScaleスライダーを表示
                    if(decalSyncScale[index].floatValue == 1.0f)
                    {
                        EditorGUI.BeginChangeCheck();
                        Vector4 st = decalTex_ST[index].vectorValue;
                        float syncedScale = EditorGUILayout.Slider("Scale", st.x, -1.0f, 1.0f);
                        if(EditorGUI.EndChangeCheck())
                        {
                            st.x = syncedScale;
                            st.y = syncedScale;
                            decalTex_ST[index].vectorValue = st;
                        }
                    }
                    
                    EditorGUI.BeginChangeCheck();
                    lilEditorGUI.UV4Decal(
                        m_MaterialEditor,
                        decalIsDecal[index],
                        decalIsLeftOnly[index],
                        decalIsRightOnly[index],
                        decalShouldCopy[index],
                        decalShouldFlipMirror[index],
                        decalShouldFlipCopy[index],
                        decalTex[index],
                        decalTex_SR[index],
                        decalTexAngle[index],
                        decalDecalAnimation[index],
                        decalDecalSubParam[index],
                        decalTex_UVMode[index]
                    );
                    // UV4Decalの初期化ボタンが押されたとき、追加プロパティもリセット
                    if(EditorGUI.EndChangeCheck())
                    {
                        // Scale同期: UV4Decal内でXが変更されたらYも同じ値に
                        if(decalSyncScale[index].floatValue == 1.0f)
                        {
                            Vector4 st = decalTex_ST[index].vectorValue;
                            st.y = st.x;
                            decalTex_ST[index].vectorValue = st;
                        }
                        
                        if(decalIsDecal[index].floatValue == 0.0f && decalTex_UVMode[index].floatValue == 0.0f)
                        {
                            decalBlendMode[index].floatValue = 0.0f;
                            decalColor[index].colorValue = Color.white;
                            decalTex_ST[index].vectorValue = new Vector4(1, 1, 0, 0);
                        }
                    }
                    
                    m_MaterialEditor.ShaderProperty(decalBlendMode[index], "Blend Mode");
                    EditorGUI.indentLevel--;
                }

                EditorGUILayout.EndVertical();
                EditorGUILayout.EndVertical();
            }
        }

        protected override void ReplaceToCustomShaders()
        {
            lts         = Shader.Find(shaderName + "/lilToon");
            ltsc        = Shader.Find("Hidden/" + shaderName + "/Cutout");
            ltst        = Shader.Find("Hidden/" + shaderName + "/Transparent");
            ltsot       = Shader.Find("Hidden/" + shaderName + "/OnePassTransparent");
            ltstt       = Shader.Find("Hidden/" + shaderName + "/TwoPassTransparent");

            ltso        = Shader.Find("Hidden/" + shaderName + "/OpaqueOutline");
            ltsco       = Shader.Find("Hidden/" + shaderName + "/CutoutOutline");
            ltsto       = Shader.Find("Hidden/" + shaderName + "/TransparentOutline");
            ltsoto      = Shader.Find("Hidden/" + shaderName + "/OnePassTransparentOutline");
            ltstto      = Shader.Find("Hidden/" + shaderName + "/TwoPassTransparentOutline");

            ltsoo       = Shader.Find(shaderName + "/[Optional] OutlineOnly/Opaque");
            ltscoo      = Shader.Find(shaderName + "/[Optional] OutlineOnly/Cutout");
            ltstoo      = Shader.Find(shaderName + "/[Optional] OutlineOnly/Transparent");

            ltstess     = Shader.Find("Hidden/" + shaderName + "/Tessellation/Opaque");
            ltstessc    = Shader.Find("Hidden/" + shaderName + "/Tessellation/Cutout");
            ltstesst    = Shader.Find("Hidden/" + shaderName + "/Tessellation/Transparent");
            ltstessot   = Shader.Find("Hidden/" + shaderName + "/Tessellation/OnePassTransparent");
            ltstesstt   = Shader.Find("Hidden/" + shaderName + "/Tessellation/TwoPassTransparent");

            ltstesso    = Shader.Find("Hidden/" + shaderName + "/Tessellation/OpaqueOutline");
            ltstessco   = Shader.Find("Hidden/" + shaderName + "/Tessellation/CutoutOutline");
            ltstessto   = Shader.Find("Hidden/" + shaderName + "/Tessellation/TransparentOutline");
            ltstessoto  = Shader.Find("Hidden/" + shaderName + "/Tessellation/OnePassTransparentOutline");
            ltstesstto  = Shader.Find("Hidden/" + shaderName + "/Tessellation/TwoPassTransparentOutline");

            ltsl        = Shader.Find(shaderName + "/lilToonLite");
            ltslc       = Shader.Find("Hidden/" + shaderName + "/Lite/Cutout");
            ltslt       = Shader.Find("Hidden/" + shaderName + "/Lite/Transparent");
            ltslot      = Shader.Find("Hidden/" + shaderName + "/Lite/OnePassTransparent");
            ltsltt      = Shader.Find("Hidden/" + shaderName + "/Lite/TwoPassTransparent");

            ltslo       = Shader.Find("Hidden/" + shaderName + "/Lite/OpaqueOutline");
            ltslco      = Shader.Find("Hidden/" + shaderName + "/Lite/CutoutOutline");
            ltslto      = Shader.Find("Hidden/" + shaderName + "/Lite/TransparentOutline");
            ltsloto     = Shader.Find("Hidden/" + shaderName + "/Lite/OnePassTransparentOutline");
            ltsltto     = Shader.Find("Hidden/" + shaderName + "/Lite/TwoPassTransparentOutline");

            ltsref      = Shader.Find("Hidden/" + shaderName + "/Refraction");
            ltsrefb     = Shader.Find("Hidden/" + shaderName + "/RefractionBlur");
            ltsfur      = Shader.Find("Hidden/" + shaderName + "/Fur");
            ltsfurc     = Shader.Find("Hidden/" + shaderName + "/FurCutout");
            ltsfurtwo   = Shader.Find("Hidden/" + shaderName + "/FurTwoPass");
            ltsfuro     = Shader.Find(shaderName + "/[Optional] FurOnly/Transparent");
            ltsfuroc    = Shader.Find(shaderName + "/[Optional] FurOnly/Cutout");
            ltsfurotwo  = Shader.Find(shaderName + "/[Optional] FurOnly/TwoPass");
            ltsgem      = Shader.Find("Hidden/" + shaderName + "/Gem");
            ltsfs       = Shader.Find(shaderName + "/[Optional] FakeShadow");

            ltsover     = Shader.Find(shaderName + "/[Optional] Overlay");
            ltsoover    = Shader.Find(shaderName + "/[Optional] OverlayOnePass");
            ltslover    = Shader.Find(shaderName + "/[Optional] LiteOverlay");
            ltsloover   = Shader.Find(shaderName + "/[Optional] LiteOverlayOnePass");

            ltsm        = Shader.Find(shaderName + "/lilToonMulti");
            ltsmo       = Shader.Find("Hidden/" + shaderName + "/MultiOutline");
            ltsmref     = Shader.Find("Hidden/" + shaderName + "/MultiRefraction");
            ltsmfur     = Shader.Find("Hidden/" + shaderName + "/MultiFur");
            ltsmgem     = Shader.Find("Hidden/" + shaderName + "/MultiGem");
        }

        // You can create a menu like this
        /*
        [MenuItem("Assets/TemplateFull/Convert material to custom shader", false, 1100)]
        private static void ConvertMaterialToCustomShaderMenu()
        {
            if(Selection.objects.Length == 0) return;
            TemplateFullInspector inspector = new TemplateFullInspector();
            for(int i = 0; i < Selection.objects.Length; i++)
            {
                if(Selection.objects[i] is Material)
                {
                    inspector.ConvertMaterialToCustomShader((Material)Selection.objects[i]);
                }
            }
        }
        */
    }
}
#endif