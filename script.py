import bpy

# レンダーセットアップ
scene = bpy.context.scene
render = scene.render
scene.cycles.samples = 5
render.engine = 'CYCLES'


# カメラを作成
bpy.ops.object.camera_add(location=(20, -40, 6.6))
# カメラオブジェクトを取得
camera = bpy.context.object
# カメラの設定
camera.name = "MyCamera"  # カメラの名前を設定
camera.rotation_euler = (0, 0, 0)  # カメラの回転角度を設定
# カメラをアクティブにする
bpy.context.scene.camera = camera

# ターゲットオブジェクトを作成
target = bpy.data.objects.new("Target", None)
bpy.context.collection.objects.link(target)
target.location = (0, 0, 2)  # ターゲットの位置を設定
# コンストレイントを作成
obj = bpy.context.object  # コンストレイントを適用するオブジェクト
look_at_constraint = obj.constraints.new('TRACK_TO')
look_at_constraint.target = target
look_at_constraint.track_axis = 'TRACK_NEGATIVE_Z'  # オブジェクトがターゲットを向く軸を設定
# コンストレイントをアクティブにする
look_at_constraint.active = True



# ワールドを取得または作成
world = scene.world
if world is None:
    world = bpy.data.worlds.new("World")
    scene.world = world
    
# 環境テクスチャを取得または作成
env_texture = world.node_tree.nodes.get("Environment Texture")
if env_texture is None:
    env_texture = world.node_tree.nodes.new("ShaderNodeTexEnvironment")
    world.node_tree.links.new(env_texture.outputs["Color"], world.node_tree.nodes["Background"].inputs["Color"])
# 画像ファイルを読み込む
image_path = "/Users/akaminelab/blender/img/kougakubu_hare2.jpg"  
# 画像ファイルのパスを指定
image = bpy.data.images.load(image_path)
# 環境テクスチャに画像を設定
env_texture.image = image
# マテリアルのマッピングを設定
texture_coord_node = world.node_tree.nodes.new(type='ShaderNodeTexCoord')
mapping_node = world.node_tree.nodes.new(type='ShaderNodeMapping')
world.node_tree.links.new(texture_coord_node.outputs['Generated'], mapping_node.inputs['Vector'])
world.node_tree.links.new(mapping_node.outputs['Vector'], env_texture.inputs['Vector'])
# マッピングのプロパティを調整
mapping_node.inputs['Rotation'].default_value[2] = -2.0944  # Z (-120 degrees in radians)
# レイの可視性のディフューズをオフにする
scene.world.cycles_visibility.diffuse = False
scene.world.cycles_visibility.glossy = False




# ico球を追加      
bpy.ops.mesh.primitive_uv_sphere_add(radius=200, location=(0, 0, 0))                                   
# 追加した平面オブジェクトを取得
dome = bpy.context.object
dome.name = "dome"
# 新しいマテリアルを作成
material = bpy.data.materials.new(name="DomeMaterial")
dome.data.materials.append(material)
# マテリアルの設定
material.use_nodes = True
nodes = material.node_tree.nodes
links = material.node_tree.links
for node in nodes:
    nodes.remove(node)
output_node = nodes.new(type='ShaderNodeOutputMaterial')
emission_node = nodes.new(type='ShaderNodeEmission')
texture_node = nodes.new(type='ShaderNodeTexImage')
# 画像テクスチャを読み込む
image = bpy.data.images.load(image_path)
# テクスチャノードに画像を設定
texture_node.image = image
# マテリアルのマッピングを設定

texture_coord_node = nodes.new(type='ShaderNodeTexCoord')
mapping_node = nodes.new(type='ShaderNodeMapping')
mapping_node.vector_type = 'TEXTURE'
links.new(texture_coord_node.outputs['UV'], mapping_node.inputs['Vector'])
links.new(mapping_node.outputs['Vector'], texture_node.inputs['Vector'])

links.new(texture_node.outputs['Color'], emission_node.inputs['Color'])
links.new(emission_node.outputs['Emission'], output_node.inputs['Surface'])
# マッピングのスケールXを-1に設定(反転)
mapping_node.inputs['Scale'].default_value[0] = -1
mapping_node.inputs['Location'].default_value[0] = 3.33  # X



