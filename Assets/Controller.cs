using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Controller : MonoBehaviour
{
    [SerializeField] private SkinnedMeshRenderer[] _linkedMeshRenderers;
    private MaterialPropertyBlock _sheet;
    private Vector4 _effectVector
    {
        get
        {
            var fwd = transform.forward / transform.localScale.z;
            var dist = Vector3.Dot(fwd, transform.position);
            Debug.Log(fwd);
            return new Vector4(fwd.x, fwd.y, fwd.z, dist);
        }
    }

    private void Update()
    {
        if (_sheet == null) _sheet = new MaterialPropertyBlock();

        _sheet.SetVector("_EffectVector", _effectVector);

        if (_linkedMeshRenderers != null) foreach(var ren in _linkedMeshRenderers) { ren.SetPropertyBlock(_sheet); }
    }

    #if UNITY_EDITOR

    Mesh _gridMesh;

    void OnDestroy()
    {
        if (_gridMesh != null)
        {
            if (Application.isPlaying)
                Destroy(_gridMesh);
            else
                DestroyImmediate(_gridMesh);
        }
    }

    void OnDrawGizmos()
    {
        if (_gridMesh == null) InitGridMesh();

        Gizmos.matrix = transform.localToWorldMatrix;

        Gizmos.color = new Color(1, 1, 0, 0.5f);
        Gizmos.DrawWireMesh(_gridMesh);
        Gizmos.DrawWireMesh(_gridMesh, Vector3.forward);

        Gizmos.color = new Color(1, 0, 0, 0.5f);
        Gizmos.DrawWireCube(Vector3.forward / 2, new Vector3(0.02f, 0.02f, 1));
    }

    void InitGridMesh()
    {
        const float ext = 0.5f;
        const int columns = 10;

        var vertices = new List<Vector3>();
        var indices = new List<int>();

        for (var i = 0; i < columns + 1; i++)
        {
            var x = ext * (2.0f * i / columns - 1);

            indices.Add(vertices.Count);
            vertices.Add(new Vector3(x, -ext, 0));

            indices.Add(vertices.Count);
            vertices.Add(new Vector3(x, +ext, 0));

            indices.Add(vertices.Count);
            vertices.Add(new Vector3(-ext, x, 0));

            indices.Add(vertices.Count);
            vertices.Add(new Vector3(+ext, x, 0));
        }

        _gridMesh = new Mesh();
        _gridMesh.hideFlags = HideFlags.DontSave;
        _gridMesh.SetVertices(vertices);
        _gridMesh.SetNormals(vertices);
        _gridMesh.SetIndices(indices.ToArray(), MeshTopology.Lines, 0);
        _gridMesh.UploadMeshData(true);
    }

    #endif
}
