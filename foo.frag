
void mainImage(out vec4 result, in vec2 fragCoord)
{
  float r = min(iResolution.x, iResolution.y);
    
	vec2 uv = fragCoord / r;
    uv.x /= 8.0;
    uv.y = 1.0 - uv.y;
    
    vec3 c = texture(iChannel0, uv).rgb;
    
    float a = texture(iChannel0, uv).a;
    bool i = bool(step(0.5, a) == 1.0);
    
    const int md = 20;
    const int h_md = md / 2;
    
    float d = float(md);
    
    for (int x = -h_md; x != h_md; ++x)
    {
        for (int y = -h_md; y != h_md; ++y)
        {
            vec2 o = vec2(float(x), float(y));
            vec2 s = (fragCoord + o) / r;
    		s.x /= 8.0;
    		s.y = 1.0 - s.y;
            
            float o_a = texture(iChannel0, s).a;
            bool o_i = bool(step(0.5, o_a) == 1.0);
            
            if (!i && o_i || i && !o_i)
                d = min(d, length(o));
        }
    }
    
    d = clamp(d, 0.0, float(md)) / float(md);
    
    if (i)
        d = -d;
    
    d = d * 0.5 + 0.5;
    d = 1.0 - d;
    
    
    float border_fade_outer = 0.1;
    float border_fade_inner = 0.01;
    float border_width = 0.25;
    vec3 border_color = vec3(1.0, 0.0, 0.0);
    
    float outer = smoothstep(0.5 - (border_width + border_fade_outer), 0.5, d);
    
    vec3 temp = vec3(0.0, 0.0, 0.0);
    vec4 border = mix(vec4(temp, 0.0), vec4(border_color, 1.0), outer);
    
    float inner = smoothstep(0.5, 0.5 + border_fade_inner, d);
    
    vec4 color = mix(border, vec4(c, 1.0), inner);
    
    result = color;
}

