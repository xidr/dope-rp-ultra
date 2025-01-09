// using CustomSRP.Runtime;
// using UnityEditor;
//
//
// [CustomEditor(typeof(CustomRenderPipelineAsset))] 
// public class CustomRenderPipelineAssetEditor : Editor {
//
//     public override void OnInspectorGUI()
//     {
//         base.OnInspectorGUI();
//         CustomRenderPipelineAsset myJukebox = (CustomRenderPipelineAsset)target;
//         myJukebox.SSAO = EditorGUILayout.Toggle("Test: Show All", myJukebox.SSAO);
//
//         if (myJukebox.SSAO)
//         {
//             EditorGUI.indentLevel++;
//             
//         }
//     }
// }