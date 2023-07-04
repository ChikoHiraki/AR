
import bpy

# Blenderファイルのディレクトリパスを取得
directory_path = bpy.path.abspath("//")

# レンダーセットアップ
scene = bpy.context.scene
render = scene.render
scene.cycles.samples = 5
render.engine = 'CYCLES'
render.image_settings.file_format = 'PNG'  # 出力フォーマットをPNGに設定


# カメラを作成
bpy.ops.object.camera_add(location=(-44, 4, 6.6))
camera = bpy.context.object         # カメラオブジェクトを取得
camera.name = "MyCamera"            # カメラの名前を設定
bpy.context.scene.camera = camera   # カメラをアクティブにする
# ターゲットオブジェクトを作成
target = bpy.data.objects.new("Target", None)
bpy.context.collection.objects.link(target)
target.location = (0, 0, 2)         # ターゲットの位置を設定
# コンストレイントを作成
look_at_constraint = camera.constraints.new('TRACK_TO')
look_at_constraint.target = target
look_at_constraint.track_axis = 'TRACK_NEGATIVE_Z'  # オブジェクトがターゲットを向く軸を設定
look_at_constraint.active = True    # コンストレイントをアクティブにする


# ワールドを取得または作成
world = scene.world
if world is None:
    world = bpy.data.worlds.new("World")
    scene.world = world
env_texture = world.node_tree.nodes.get("Environment Texture")
if env_texture is None:                         # 環境テクスチャを取得または作成
    env_texture = world.node_tree.nodes.new("ShaderNodeTexEnvironment")
    world.node_tree.links.new(env_texture.outputs["Color"], world.node_tree.nodes["Background"].inputs["Color"])
background_image_path = directory_path+"/img/background.jpg"    # 画像ファイルを読み込む
background_image = bpy.data.images.load(background_image_path)
env_texture.image = background_image
scene.world.cycles_visibility.diffuse = False   # レイの可視性のディフューズをオフにする
scene.world.cycles_visibility.glossy = False


# houseを非表示にする
house = bpy.data.objects.get("house")
if house:
    house.hide_viewport = True
    house.hide_render = True
    
# レンダリングの実行
render.filepath = directory_path+"/img/camera.png"  
bpy.ops.render.render(write_still=True)

# houseを表示する
house = bpy.data.objects.get("house")
if house:
    house.hide_viewport = False
    house.hide_render = False



# houseのマテリアルを取得
house_material = bpy.data.materials.new(name="House1Material")
house.data.materials.append(house_material)
house.active_material = house_material
house_material.use_nodes = True
house_nodes = house_material.node_tree.nodes
house_links = house_material.node_tree.links
for node in house_nodes:
    house_nodes.remove(node)
house_output_node = house_nodes.new(type='ShaderNodeOutputMaterial')
house_bsdf = house_nodes.new(type='ShaderNodeBsdfPrincipled')
house_texture = house_nodes.new(type='ShaderNodeTexImage')
house_image_path = directory_path+"/img/house_texture.png"  
house_image = bpy.data.images.load(house_image_path)
house_texture.image = house_image
house_links.new(house_texture.outputs['Color'], house_bsdf.inputs['Base Color'])
house_links.new(house_bsdf.outputs['BSDF'], house_output_node.inputs['Surface'])



# uv球を追加      
bpy.ops.mesh.primitive_uv_sphere_add(radius=200, location=(0, 0, 0))                                   
dome = bpy.context.object  # 追加したオブジェクトを取得
dome.name = "dome"
DomeMaterial = bpy.data.materials.new(name="DomeMaterial")  
dome.data.materials.append(DomeMaterial)      # 新しいマテリアルを作成
# マテリアルの設定
DomeMaterial.use_nodes = True
dome_nodes = DomeMaterial.node_tree.nodes
dome_links = DomeMaterial.node_tree.links
for node in dome_nodes:
    dome_nodes.remove(node)
dome_output_node = dome_nodes.new(type='ShaderNodeOutputMaterial')
dome_emission_node = dome_nodes.new(type='ShaderNodeEmission')
dome_texture_node = dome_nodes.new(type='ShaderNodeTexImage')
dome_texture_node.image = background_image    # 画像テクスチャを読み込む
# マテリアルのマッピングを設定
dome_texture_coord_node = dome_nodes.new(type='ShaderNodeTexCoord')
dome_mapping_node = dome_nodes.new(type='ShaderNodeMapping')
dome_mapping_node.vector_type = 'TEXTURE'
dome_links.new(dome_texture_coord_node.outputs['UV'], dome_mapping_node.inputs['Vector'])
dome_links.new(dome_mapping_node.outputs['Vector'], dome_texture_node.inputs['Vector'])
dome_links.new(dome_texture_node.outputs['Color'], dome_emission_node.inputs['Color'])
dome_links.new(dome_emission_node.outputs['Emission'], dome_output_node.inputs['Surface'])
dome_mapping_node.inputs['Scale'].default_value[0] = -1  # マッピングのスケールXを-1に設定(反転)



# 平面を追加                                         
bpy.ops.mesh.primitive_plane_add(size=50, enter_editmode=False, align='WORLD', location=(0, 0, -0.1), scale=(1, 1, 1))
plane = bpy.context.object   # 追加した平面オブジェクトを取得
plane.name = "Plane"
bpy.context.view_layer.objects.active = plane 
bpy.ops.object.mode_set(mode='EDIT')      # 平面を細分化
bpy.ops.mesh.subdivide(number_cuts=10)
bpy.ops.mesh.subdivide(number_cuts=10)
bpy.ops.object.mode_set(mode='OBJECT')
planeMaterial = bpy.data.materials.new(name="PlaneMaterial")   # 新しいマテリアルを作成
plane.data.materials.append(planeMaterial)
# マテリアルの設定
planeMaterial.use_nodes = True
plane_nodes = planeMaterial.node_tree.nodes
plane_links = planeMaterial.node_tree.links
for node in plane_nodes:
    plane_nodes.remove(node)
plane_output_node = plane_nodes.new(type='ShaderNodeOutputMaterial')
plane_emission_node = plane_nodes.new(type='ShaderNodeEmission')
plane_texture_node = plane_nodes.new(type='ShaderNodeTexImage')
plane_color_node = plane_nodes.new(type="ShaderNodeBsdfDiffuse")

plane_image_path = directory_path+"/img/camera.png"            # 画像テクスチャを読み込む
plane_image = bpy.data.images.load(plane_image_path)
plane_texture_node.image = plane_image
# マテリアルのマッピングを設定
plane_texture_coord_node = plane_nodes.new(type='ShaderNodeTexCoord')
plane_mapping_node = plane_nodes.new(type='ShaderNodeMapping')
plane_mapping_node.vector_type = 'TEXTURE'
plane_links.new(plane_texture_coord_node.outputs['Window'], plane_mapping_node.inputs['Vector'])
plane_links.new(plane_mapping_node.outputs['Vector'], plane_texture_node.inputs['Vector'])
plane_links.new(plane_texture_node.outputs['Color'], plane_emission_node.inputs['Color'])
plane_links.new(plane_emission_node.outputs['Emission'], plane_output_node.inputs['Surface'])
plane_links.new(plane_texture_node.outputs['Color'], plane_color_node.inputs['Color'])


"""______ ここから上は編集しなくて良い _____________________________________________"""







house_bake_texture1 = house_nodes.new(type='ShaderNodeTexImage') # houseにベイク用のテクスチャを用意
new_image1 = bpy.data.images.new("house_bake_from_dome_and_ground", 1024, 1024)
house_bake_texture1.image = new_image1
house_nodes.active = house_bake_texture1


# ドーム.地面から建造物への光をベイク
render.bake.use_pass_direct = True
render.bake.use_pass_indirect = True
bpy.ops.object.select_all(action='DESELECT')
house.select_set(True)
bpy.context.view_layer.objects.active = house
bpy.ops.object.bake(type='DIFFUSE')
# ベイク結果を保存
output_path1 = directory_path+"/img/house_bake_from_dome_and_ground.png"
bpy.data.images['house_bake_from_dome_and_ground'].save_render(filepath=output_path1)



# domeを非表示にする
if dome:
    dome.hide_viewport = True
    dome.hide_render = True

# Planeの放射を解除する（出力をカラーに変更）
plane_links.new(plane_color_node.outputs['BSDF'], plane_output_node.inputs['Surface'])

# planeを非表示にする
if plane:
    plane.hide_viewport = True
    plane.hide_render = True




# 太陽を追加  
light_data = bpy.data.lights.new(name="SunLight", type='SUN')
light_object = bpy.data.objects.new(name="Sun", object_data=light_data)
scene.collection.objects.link(light_object)
light_object.location = (3.5, -30, 30)    # 位置を指定
# コンストレイントを作成
look_at_constraint2 = light_object.constraints.new('TRACK_TO')
look_at_constraint2.target = target
look_at_constraint2.track_axis = 'TRACK_NEGATIVE_Z'  # オブジェクトがターゲットを向く軸を設定
look_at_constraint.active = True          # コンストレイントをアクティブにする

house_bake_texture2 = house_nodes.new(type='ShaderNodeTexImage') # ベイク用のテクスチャ
new_image2 = bpy.data.images.new("house_bake_from_sun", 1024, 1024)
house_bake_texture2.image = new_image2
house_nodes.active = house_bake_texture2


# 太陽から建造物への光をベイク
house.select_set(True)
bpy.context.view_layer.objects.active = house
bpy.ops.object.bake(type='DIFFUSE')
# ベイク結果を保存
output_path2 = directory_path+"/img/house_bake_from_sun.png"
bpy.data.images['house_bake_from_sun'].save_render(filepath=output_path2)

house_links.new(house_bake_texture2.outputs['Color'], house_bsdf.inputs['Emission'])
house_bsdf.inputs[20].default_value = 3

# 太陽を非表示にする
if light_object:
    light_object.hide_viewport = True
    light_object.hide_render = True

# planeを表示する
if plane:
    plane.hide_viewport = False
    plane.hide_render = False
    
    


# 建造物から地面への光をベイク
plane_bake_texture = plane_nodes.new(type='ShaderNodeTexImage') # ベイク用のテクスチャ
new_image4 = bpy.data.images.new("plane_bake_from_house", 1024, 1024)
plane_bake_texture.image = new_image4
plane_nodes.active = plane_bake_texture


# 建造物から地面への光をベイク
plane.select_set(True)
house.select_set(False)
bpy.context.view_layer.objects.active = plane
bpy.ops.object.bake(type='DIFFUSE')

# ベイク結果を保存
output_path4 = directory_path+"/img/plane_bake_from_house.png"
bpy.data.images['plane_bake_from_house'].save_render(filepath=output_path4)


# Plane nodeの調整
plane_shader_mix1 = plane_nodes.new(type="ShaderNodeAddShader")
plane_links.new(plane_color_node.outputs['BSDF'], plane_shader_mix1.inputs[0])
plane_links.new(plane_emission_node.outputs['Emission'], plane_shader_mix1.inputs[1])
plane_emission_node2 = plane_nodes.new(type='ShaderNodeEmission')
plane_links.new(plane_bake_texture.outputs['Color'], plane_emission_node2.inputs['Color'])
plane_shader_mix2 = plane_nodes.new(type="ShaderNodeAddShader")
plane_links.new(plane_shader_mix1.outputs['Shader'], plane_shader_mix2.inputs[0])
plane_links.new(plane_emission_node2.outputs['Emission'], plane_shader_mix2.inputs[1])
plane_links.new(plane_shader_mix2.outputs['Shader'], plane_output_node.inputs['Surface'])
plane_emission_node.inputs[1].default_value = 0.3
plane_emission_node2.inputs[1].default_value = 5


house_links.new(house_bake_texture1.outputs['Color'], house_bsdf.inputs['Emission'])
house_bsdf.inputs[20].default_value = 1