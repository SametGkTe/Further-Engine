package shaders;

import flixel.FlxBasic;
import flixel.FlxSprite;

class WarpEffect extends FlxBasic
{
	public var shader:WarpShader;

	public function new(sprite:FlxSprite):Void
	{
		super();
		shader = new WarpShader();
		sprite.shader = shader;
		shader.iTime.value = [0.0];
		shader.portalScale.value = [0.0];
		shader.portalAlpha.value = [0.0];
		shader.portalBrightness.value = [1.0];
		shader.portalEdgeSoftness.value = [0.15];
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		shader.iTime.value[0] += elapsed;
	}

	public function setPortalScale(v:Float):Void
	{
		shader.portalScale.value = [v];
	}

	public function getPortalScale():Float
	{
		return shader.portalScale.value[0];
	}

	public function setPortalAlpha(v:Float):Void
	{
		shader.portalAlpha.value = [v];
	}

	public function getPortalAlpha():Float
	{
		return shader.portalAlpha.value[0];
	}

	public function setPortalBrightness(v:Float):Void
	{
		shader.portalBrightness.value = [v];
	}

	public function getPortalBrightness():Float
	{
		return shader.portalBrightness.value[0];
	}

	public function setPortalEdgeSoftness(v:Float):Void
	{
		shader.portalEdgeSoftness.value = [v];
	}

	public function getPortalEdgeSoftness():Float
	{
		return shader.portalEdgeSoftness.value[0];
	}
}

class WarpShader extends FlxShader
{
	@:glFragmentSource('
	#pragma header
	uniform float iTime;
	uniform float portalScale;
	uniform float portalAlpha;
	uniform float portalBrightness;
	uniform float portalEdgeSoftness;

	#define brightness 2.
	#define ray_brightness 4.
	#define gamma 6.
	#define spot_brightness 0.
	#define ray_density 6.5
	#define curvature 70.
	#define red 2.9
	#define green .7
	#define blue 3.5
	#define PROCEDURAL_NOISE

	float hash(float n) {
		return fract(sin(n) * 43758.5453);
	}

	float noise(vec2 x) {
		x *= 1.75;
		vec2 p = floor(x);
		vec2 f = fract(x);
		f = f * f * (3.0 - 2.0 * f);
		float n = p.x + p.y * 57.0;
		return mix(mix(hash(n + 0.0), hash(n + 1.0), f.x),
				   mix(hash(n + 57.0), hash(n + 58.0), f.x), f.y);
	}

	float fbm(vec2 p) {
		float z = 2.0;
		float rz = 0.0;
		p *= 0.25;
		for (float i = 1.0; i < 6.0; i++) {
			rz += abs((noise(p) - 0.5) * 2.0) / z;
			z *= 2.0;
			p *= 2.0 * mat2(0.80, 0.60, -0.60, 0.80);
		}
		return rz;
	}

	void main() {
		vec2 fragCoord = openfl_TextureCoordv * openfl_TextureSize;
		vec2 iResolution = openfl_TextureSize;

		vec2 uv = fragCoord.xy / iResolution.xy - 0.5;
		uv.x *= iResolution.x / iResolution.y;

		float dist = length(uv);

		float effectiveScale = max(portalScale, 0.001);
		vec2 scaledUV = uv / effectiveScale;

		float t = -iTime * 0.03;
		scaledUV *= curvature * 0.05 + 0.0001;

		float r = length(scaledUV);
		vec2 norm_uv = normalize(scaledUV);
		float x = dot(norm_uv, vec2(0.5, 0.0)) + t;
		float y = dot(norm_uv, vec2(0.0, 0.5)) + t;

		x = fbm(vec2(y * ray_density * 0.5, r + x * ray_density * 0.2));
		y = fbm(vec2(r + y * ray_density * 0.1, x * ray_density * 0.5));

		float val = fbm(vec2(r + y * ray_density, r + x * ray_density - y));
		val = smoothstep(gamma * 0.02 - 0.1, ray_brightness + gamma * 0.02 - 0.1 + 0.001, val);
		val = sqrt(val);

		vec3 col = val / vec3(red, green, blue);
		col = clamp(1.0 - col, 0.0, 1.0);
		col = mix(col, vec3(1.0), spot_brightness - r / 0.1 / curvature * 200.0 / brightness);
		col = clamp(col, 0.0, 1.0);
		col = pow(col, vec3(1.7));

		col *= portalBrightness;

		float edgeRadius = portalScale * 0.95;
		float edgeFade = 1.0 - smoothstep(edgeRadius - portalEdgeSoftness, edgeRadius, dist);

		float finalAlpha = portalAlpha * edgeFade;

		if (finalAlpha <= 0.001) {
			gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
			return;
		}

		gl_FragColor = vec4(col * finalAlpha * 0.15, finalAlpha * 0.3);
	}
	')

	public function new()
	{
		super();
	}
}