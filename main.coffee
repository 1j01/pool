
TAU = Math.PI + Math.PI # or C/r
T = THREE
P = Physijs
V3 = T.Vector3
randy = (x)-> Math.random()*x-x/2
rand = (x)-> Math.random()*x

P.scripts.worker = './lib/physijs_worker.js';
P.scripts.ammo = './ammo.js';


# SCENE
scene = new P.Scene(fixedTimeStep: 1/30)
scene.setGravity(new V3(0, -300, 0))

# CAMERA
WIDTH = window.innerWidth
HEIGHT = window.innerHeight
ASPECT = WIDTH / HEIGHT
VIEW_ANGLE = 45
NEAR = 0.1
FAR = 20000
camera = new T.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR)
scene.add(camera)
camera.position.set(150, 550, 400)
camera.lookAt(scene.position)

# RENDERER
renderer = 
	if Detector.webgl
		new T.WebGLRenderer(antialias: yes)
	else
		new T.CanvasRenderer()

renderer.setSize(WIDTH, HEIGHT)
document.body.appendChild(renderer.domElement)

$(window).on 'resize', ->
	WIDTH = window.innerWidth
	HEIGHT = window.innerHeight
	ASPECT = WIDTH / HEIGHT
	
	renderer.setSize(WIDTH, HEIGHT)
	camera.aspect = ASPECT
	camera.updateProjectionMatrix()


# CONTROLS
controls = new T.OrbitControls(camera, renderer.domElement)

# LIGHTING
light = new T.PointLight(0xffffff, 1, 10000)
light.position.set(0, 100, 0)
scene.add(light)

###
directionalLight = new T.DirectionalLight(0xffffff, 0.5)
directionalLight.position.set(0, 1, 0)
scene.add(directionalLight)

skyLight = new T.HemisphereLight(0xffffff, 0x0000ff, 0.5)
scene.add(skyLight)
###

# SKYBOX/FOG
skyBoxGeometry = new T.BoxGeometry(10000, 10000, 10000)
skyBoxMaterial = new T.MeshBasicMaterial(color: 0xaabDf0, side: T.BackSide)
skyBox = new T.Mesh(skyBoxGeometry, skyBoxMaterial)
scene.add(skyBox)


###################################

ground_material = P.createMaterial(
	new T.MeshBasicMaterial(color: 0x006D10)
	0.8 # high friction
	0.3 # low restitution
);
#ground_material.map.wrapS = ground_material.map.wrapT = T.RepeatWrapping
#ground_material.map.repeat.set(3, 3)

ground = new P.BoxMesh(
	new T.CubeGeometry(2000, 50, 1000)
	ground_material
	0 # mass, 0 = static
)
ground.position.set(0, -500, 0)
ground.receiveShadow = true
scene.add(ground)

balls = for i in [0..15]
	canvas = document.createElement('canvas')
	W = H = 1024
	canvas.width = W
	canvas.height = H
	ctx = canvas.getContext('2d')
	
	white = '#FEFFEA'
	
	ctx.fillStyle = white
	ctx.fillRect(0, 0, W, H)
	
	colors = [
		'(cue ball)'
		'#FCCF04','#1544AD','#E81D13','#7C2E7C','#FF6901','#00680F','#8A0A11','#0B0806'
		'#FCCF04','#1544AD','#E81D13','#7C2E7C','#FF6901','#00680F','#8A0A11','#0B0806'
	]
	ctx.fillStyle = colors[i]
	if i > 8
		a = 0.3
		ctx.fillRect(0, H*a, W, H*(1-a*2))
	else
		ctx.fillRect(0, 0, W, H)
	
	if i > 0
		
		ctx.translate(W/2, H/2)
		ctx.scale(0.5, 0.9)
		
		ctx.beginPath()
		ctx.arc(0, 0, H/7, 0, TAU)
		ctx.fillStyle = white
		ctx.fill()
		
		ctx.textBaseline = 'middle'
		ctx.textAlign = 'center'
		ctx.font = (H/4)+'px Georgia'
		ctx.fillStyle = 'black'
		ctx.fillText(i, 0, -H*0.04)
	else
		# little red dot maybe?
	
	map = new T.Texture(canvas)
	map.needsUpdate = true

	ball = new P.SphereMesh(
		new T.SphereGeometry(25, 25, 25)
		new T.MeshPhongMaterial
			color: 0xffffff
			shininess: 100
			emissive: 0xaaaaaa
			specular: 0xbbbbbb
			map: map
		undefined
		{ restitution: 100.5, friction: 0.9 }
	)
	
	ball.position.set(randy(500), randy(500), randy(500))
	ball.rotation.x = rand(TAU)
	ball.rotation.y = rand(TAU)
	ball.rotation.z = rand(TAU)
	scene.add(ball)
	
	ball

###################################
###
unprojector = new T.Projector()
mouse = {x: 0, y: 0}

$('body').on 'mousemove', (e)-> 
	e.preventDefault()
	
	mouse.x = (e.originalEvent.offsetX / WIDTH) * 2 - 1
	mouse.y = (e.originalEvent.offsetY / HEIGHT) * -2 + 1
	
	vector = new T.Vector3(mouse.x, mouse.y, 1)
	unprojector.unprojectVector(vector, camera)
	ray = new T.Raycaster(camera.position, vector.sub(camera.position).normalize())
	
	intersects = ray.intersectObjects(balls)
	
	if mouse.intersect
		mid = mouse.intersect.face.materialIndex
		materials[mid].emissive.setHex(0x000000)
		materials[mid].needsUpdate = true
	
	mouse.intersect = intersect = intersects[0]
	
	if mouse.intersect and e.type isnt 'mousemove'
		mid = intersect.face.materialIndex
		materials[mid].emissive.setHex(0xa0a0a0)
		materials[mid].needsUpdate = true
		
		canvas = materials[mid].map.image
		#canvas = canvases[mid]
		ctx = canvas.getContext('2d')
		ctx.fillStyle = '#f0f'
		ctx.fillRect(50, 50, 50, 50)
###

do animate = ->
	requestAnimationFrame(animate)
	scene.simulate(undefined, 1)
	renderer.render(scene, camera)
	controls.update()
