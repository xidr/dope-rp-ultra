using DopeRP.CPU;
using UnityEditor;
using UnityEngine;

partial class PostFXStack {

    partial void ApplySceneViewState ();

#if UNITY_EDITOR

    partial void ApplySceneViewState () {
        if (RAPI.CurCamera.cameraType == CameraType.SceneView && !SceneView.currentDrawingSceneView.sceneViewState.showImageEffects) {
            settings = null;
        }
    }

#endif
}