import java.util.ArrayList;

PImage imgF, imgL, imgT;
ArrayList<Particle> pointCloud;

int step = 5;       
int boxW = 1024;    
float sphereR = 480; 

// ===== 视频导出控制 =====
int exportFPS = 24;          
int totalExportSeconds = 10; 
int maxFrames = exportFPS * totalExportSeconds; 
int frameCounter = 0;
boolean isExporting = false; 

// ===== 动态与运镜控制 =====
float time = 0;          
float globalFlowSpeed = 1.2;  
float globalFlowAmp = 150.0;  

int beatPeriod = exportFPS;  
int attackFrames = 4;        
int releaseFrames = 15;      

float baseCamAngle = 0; 
float baseCamY = -150;  

void setup() {
  size(1024, 1024, P3D);
  frameRate(exportFPS);      
  colorMode(RGB, 255, 255, 255, 255);
  
  println("=============================");
  println("【生命之核：60度大视差增强版】");
  println("调整: 水平旋转翻倍至 60度 | 增强 3D 景深与视差");
  println("提示: 拖拽鼠标可预览构图。按 'e' 键开始录制。");
  
  imgF = loadImage("flat_Front.png");
  imgL = loadImage("flat_Left.png");
  imgT = loadImage("flat_Top.png");

  pointCloud = new ArrayList<Particle>();
  generatePointCloud();
  println("点云生成完毕！当前粒子数: " + pointCloud.size());
}

void draw() {
  background(0); 
  
  float camRadius, camAngle, camY;
  float transitionFactor = 0; 
  float rotX = 0, rotZ = 0;
  
  if (isExporting) {
    float progress = (float)frameCounter / maxFrames; 
    float easeProgress = progress < 0.5 ? 2 * progress * progress : 1 - pow(-2 * progress + 2, 2) / 2;
    
    // 摄像机推进：从 1350 推至 1050 
    camRadius = lerp(1350, 1050, progress); 
    
    // 【核心增强】：水平环绕从 0（侧面）开始，旋转幅度加倍至 60 度 (PI/3)
    camAngle = lerp(0, PI/3, easeProgress);    
    
    // 镜头下沉：从俯视落至平视
    camY = lerp(-150, 0, easeProgress);    
    
    // 空间多维翻滚 (保持原本的微重力漂浮感)
    rotX = lerp(PI/18, -PI/12, easeProgress);  
    rotZ = lerp(-PI/24, PI/18, easeProgress);  
    
    time += 0.015; 
    
    // 平滑觉醒过渡 (2秒内)
    float rawT = min(1.0, (float)frameCounter / 48.0);
    transitionFactor = rawT * rawT * (3 - 2 * rawT); 
    
  } else {
    // 待机预览模式
    camRadius = 1350; 
    if (mousePressed) { 
      baseCamAngle -= (mouseX - pmouseX) * 0.005; 
      baseCamY -= (mouseY - pmouseY) * 1.0; 
    }
    camAngle = baseCamAngle;
    camY = baseCamY;
    transitionFactor = 0; 
    
    // 保持初始微倾斜姿态
    rotX = PI/18;
    rotZ = -PI/24;
  }

  // 1. 设置摄像机位置
  float camX = cos(camAngle) * camRadius;
  float camZ = sin(camAngle) * camRadius;
  camera(camX, camY, camZ, 0, 0, 0, 0, 1, 0); 
  
  // 2. 赋予整个世界多维失重翻滚
  rotateX(rotX);
  rotateZ(rotZ);
  
  hint(ENABLE_DEPTH_SORT);

  for (Particle p : pointCloud) {
    p.update(time, transitionFactor);
    p.display(transitionFactor);
  }
  
  if (isExporting) {
    saveFrame("export/frame_#####.jpg"); 
    frameCounter++;
    
    if (frameCounter % 24 == 0) println(">>>> 已成功录制: " + (frameCounter/24) + " 秒...");
    
    if (frameCounter >= maxFrames) {
      isExporting = false;
      println("【录制完美杀青】成功输出 240 帧 JPG。60度大视差运镜完成！");
      exit(); 
    }
  }
}

void generatePointCloud() {
  int hW = boxW / 2;

  for (int x = -hW; x < hW; x += step) {
    for (int y = -hW; y < hW; y += step) {
      for (int z = -hW; z < hW; z += step) {
        
        if (sqrt(x*x + y*y + z*z) > sphereR) continue; 

        int uF = x + hW; int vF = y + hW;
        int uL = z + hW; int vL = y + hW;
        int uT = x + hW; int vT = z + hW;
        
        color cF = imgF.get(uF, vF);
        color cL = imgL.get(uL, vL);
        color cT = imgT.get(uT, vT);
        
        boolean rF = isRed(cF), rL = isRed(cL), rT = isRed(cT);
        boolean bF = isBlue(cF), bL = isBlue(cL), bT = isBlue(cT);
        boolean gF = isGreen(cF), gL = isGreen(cL), gT = isGreen(cT);
        boolean yF = isYellow(cF), yL = isYellow(cL), yT = isYellow(cT);

        if (rF || rL || rT) continue; 
        else if (bF || bL || bT) {
          if (random(1) < 0.12) {
            boolean isDrifter = random(1) < 0.008; 
            pointCloud.add(new Particle(x, y, z, color(150, 180, 255, 120), 2, 1, isDrifter)); 
          }
        }
        else if (gF || gL || gT) {
          if (random(1) < 0.85) pointCloud.add(new Particle(x, y, z, color(255, 110, 110, 100), 3, 2, false)); 
        }
        else if (yF && yL && yT) pointCloud.add(new Particle(x, y, z, color(255, 30, 40, 255), 4, 3, false)); 
      }
    }
  }
}

boolean isRed(color c) { return red(c) > 200 && green(c) < 50 && blue(c) < 50; }
boolean isBlue(color c) { return blue(c) > 200 && red(c) < 50 && green(c) < 50; }
boolean isGreen(color c) { return green(c) > 200 && red(c) < 50 && blue(c) < 50; }
boolean isYellow(color c) { return red(c) > 200 && green(c) > 200 && blue(c) < 50; }

void keyPressed() {
  if ((key == 'e' || key == 'E') && !isExporting) {
    isExporting = true;
    frameCounter = 0; 
    baseCamAngle = 0;
    baseCamY = -150;
    println("▶ 摄影机归位，60度大环绕运镜启动...");
  }
}

class Particle {
  PVector origin, pos;    
  color c; 
  int pSize, layerType;  
  float randomSeed; 
  boolean isDrifter; 

  Particle(float x, float y, float z, color _c, int _s, int _layer, boolean _drifter) { 
    origin = new PVector(x, y, z); pos = new PVector(x, y, z);
    c = _c; pSize = _s; layerType = _layer; isDrifter = _drifter; randomSeed = random(1000);
  }
  
  void update(float t, float transition) {
    float ns = 0.0015; 
    float sharedNoiseX = (noise(origin.x * ns, origin.y * ns, t * globalFlowSpeed) - 0.5) * 2.0;
    float sharedNoiseY = (noise(origin.y * ns, origin.z * ns, t * globalFlowSpeed + 100) - 0.5) * 2.0;
    float sharedNoiseZ = (noise(origin.z * ns, origin.x * ns, t * globalFlowSpeed + 200) - 0.5) * 2.0;
    PVector flowDisplacement = new PVector(sharedNoiseX, sharedNoiseY, sharedNoiseZ).mult(globalFlowAmp);

    PVector targetPos = origin.copy(); 

    if (layerType == 3) {
      int cycle = frameCount % beatPeriod; 
      float pulse = 0;
      if (cycle < attackFrames) {
        pulse = lerp(0, -12.0, (float)cycle / attackFrames); 
      } else if (cycle < attackFrames + releaseFrames) {
        pulse = lerp(-12.0, 0, 1.0 - pow(1.0 - ((float)(cycle - attackFrames) / releaseFrames), 3)); 
      }
      targetPos = PVector.add(origin, origin.copy().normalize().mult(pulse)).add(flowDisplacement);
      
    } else if (layerType == 2) {
      targetPos = PVector.add(origin, flowDisplacement);
      
    } else if (layerType == 1) {
      if (isDrifter) {
        float driftNs = 0.004;
        float dx = (noise(origin.x * driftNs, origin.y * driftNs, t) - 0.5) * 2.0;
        float dy = (noise(origin.y * driftNs, origin.z * driftNs, t + 10) - 0.5) * 2.0;
        float dz = (noise(origin.z * driftNs, origin.x * driftNs, t + 20) - 0.5) * 2.0;
        targetPos.add(new PVector(dx, dy, dz).mult(2.5)).add(origin.copy().normalize().mult(0.2));
      } else {
        float fastNs = 0.02;
        float nx = (noise(origin.x * fastNs, origin.y * fastNs, t) - 0.5) * 2.0;
        float ny = (noise(origin.y * fastNs, origin.z * fastNs, t + 10) - 0.5) * 2.0;
        float nz = (noise(origin.z * fastNs, origin.x * fastNs, t + 20) - 0.5) * 2.0;
        targetPos = PVector.add(origin, new PVector(nx * 6, ny * 6, nz * 6));
      }
    }
    
    pos = PVector.lerp(origin, targetPos, transition);
  }
  
  void display(float transition) {
    strokeWeight(pSize);
    
    if (layerType == 3) {
      int cycle = frameCount % beatPeriod;
      float darkenFactor = 1.0; 
      if (cycle < attackFrames) {
        darkenFactor = lerp(1.0, 0.3, (float)cycle / attackFrames); 
      } else if (cycle < attackFrames + releaseFrames) {
        darkenFactor = lerp(0.3, 1.0, 1.0 - pow(1.0 - ((float)(cycle - attackFrames) / releaseFrames), 3)); 
      }
      float finalDarken = lerp(1.0, darkenFactor, transition);
      stroke(red(c) * finalDarken, green(c) * finalDarken, blue(c) * finalDarken, 255);
      
    } else if (layerType == 2) {
      float alphaFluctuation = noise(randomSeed + time * 0.8) * 70 + 50; 
      float finalAlpha = lerp(120, alphaFluctuation, transition);
      stroke(red(c), green(c), blue(c), finalAlpha);
      
    } else if (layerType == 1) {
      float flicker = pow(noise(randomSeed + time * 2.5), 2) * 220 + 10; 
      float finalAlpha = lerp(120, flicker, transition);
      stroke(red(c), green(c), blue(c), finalAlpha); 
    }
    
    point(pos.x, pos.y, pos.z);
  }
}
