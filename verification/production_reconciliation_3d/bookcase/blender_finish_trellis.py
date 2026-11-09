import bpy, json, os, sys
from pathlib import Path
from mathutils import Vector

args=sys.argv[sys.argv.index('--')+1:]
src=Path(args[0]).resolve(); dst=Path(args[1]).resolve(); decimate_ratio=float(args[2]) if len(args)>2 else 1.0
if not src.is_file(): raise FileNotFoundError(src)
dst.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
for block in bpy.data.collections:
    if block.users == 0: bpy.data.collections.remove(block)
bpy.ops.import_scene.gltf(filepath=str(src))
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
if len(meshes)!=1: raise RuntimeError(f'expected one model mesh after clearing startup scene, got {len(meshes)}')
obj=meshes[0]
source_triangles=sum(max(0,len(p.vertices)-2) for p in obj.data.polygons)
if decimate_ratio < 1.0:
    if decimate_ratio <= 0.0: raise ValueError('decimate ratio must be positive')
    dec=obj.modifiers.new('TRELLIS2_Gameplay_Decimation','DECIMATE'); dec.ratio=decimate_ratio
    bpy.context.view_layer.objects.active=obj; bpy.ops.object.modifier_apply(modifier=dec.name)
# Flatten the GLTF importer axis transform, preserve the TRELLIS geometry and PBR material.
bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active=obj
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
target=Vector((32.0,17.0,63.0))
source=Vector(obj.dimensions)
if min(source) <= 1e-6: raise RuntimeError(f'invalid source dimensions: {tuple(source)}')
ratios=Vector((target.x/source.x, target.y/source.y, target.z/source.z))
obj.scale=ratios
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
bpy.context.view_layer.update()
# Center footprint and place the bookcase on the floor plane.
pts=[obj.matrix_world @ Vector(c) for c in obj.bound_box]
mn=Vector(tuple(min(p[i] for p in pts) for i in range(3)))
mx=Vector(tuple(max(p[i] for p in pts) for i in range(3)))
obj.location += Vector((-(mn.x+mx.x)/2.0, -(mn.y+mx.y)/2.0, -mn.z))
bpy.context.view_layer.update()
# Normalize embedded web textures to PNG for the RoomScale/Godot GLTF import path.
texture_files=[]
for mi,mat in enumerate(bpy.data.materials):
    if not mat.use_nodes: continue
    for ni,node in enumerate(mat.node_tree.nodes):
        if node.type!='TEX_IMAGE' or node.image is None: continue
        img=node.image
        png_path=dst.parent / f'{dst.stem}-texture-{mi}-{ni}.png'
        img.filepath_raw=str(png_path)
        img.file_format='PNG'
        img.save()
        img.pack()
        texture_files.append({'name':img.name,'file':str(png_path),'width':img.size[0],'height':img.size[1]})
# Export one centered, grounded, dimensioned mesh with embedded PNG PBR textures.
bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active=obj
result=bpy.ops.export_scene.gltf(filepath=str(dst), export_format='GLB', export_image_format='AUTO', export_materials='EXPORT', export_yup=True, export_apply=True, export_cameras=False, export_lights=False, export_animations=False)
if 'FINISHED' not in result or not dst.is_file(): raise RuntimeError(f'GLB export failed: {result}')
# Reimport into a clean scene to verify exported content, dimensions, and textures.
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(dst))
final_meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
if len(final_meshes)!=1: raise RuntimeError(f'export has {len(final_meshes)} mesh objects')
obj=final_meshes[0]; bpy.context.view_layer.update()
pts=[obj.matrix_world @ Vector(c) for c in obj.bound_box]
mn=Vector(tuple(min(p[i] for p in pts) for i in range(3))); mx=Vector(tuple(max(p[i] for p in pts) for i in range(3)))
dims=mx-mn
tris=sum(max(0,len(p.vertices)-2) for o in final_meshes for p in o.data.polygons)
images=[{'name':im.name,'size':list(im.size),'format':im.file_format} for im in bpy.data.images]
report={'blender':bpy.app.version_string,'source_glb':str(src),'output_glb':str(dst),'output_bytes':dst.stat().st_size,'source_dimensions_blender_xyz':list(source),'target_dimensions_blender_xyz':list(target),'applied_scale_xyz':list(ratios),'verified_dimensions_blender_xyz':list(dims),'verified_bounds_min':list(mn),'verified_triangles':tris,'source_triangles':source_triangles,'decimate_ratio':decimate_ratio,'mesh_count':len(final_meshes),'material_count':len(bpy.data.materials),'images':images,'converted_textures':texture_files,'normal_axis':'Blender Z-up; exported GLTF Y-up; Godot applies GLTF axis conversion'}
report_path=dst.with_suffix('.blender-finish.json'); report_path.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('ROOMSCALE_TRELLIS_FINISH_JSON='+json.dumps(report))
