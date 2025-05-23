<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>图片裁剪</title>
    <style>
        body, html {
            margin: 0;
            padding: 0;
            height: 100%;
            overflow: hidden;
            background: #000;
        }
        #container {
            width: 100%;
            height: 100%;
            position: relative;
            overflow: hidden;
            touch-action: none;
        }
        #canvas {
            position: absolute;
            top: 0;
            left: 0;
        }
        #cropBox {
            position: absolute;
            border: 2px dashed #fff;
            background: rgba(0, 0, 0, 0.3);
            pointer-events: none;
        }
        .handle {
            position: absolute;
            width: 20px;
            height: 20px;
            background: #fff;
            opacity: 0.7;
            pointer-events: auto;
            cursor: pointer;
        }
        #topHandle { top: -10px; left: 50%; transform: translateX(-50%); }
        #bottomHandle { bottom: -10px; left: 50%; transform: translateX(-50%); }
        #leftHandle { left: -10px; top: 50%; transform: translateY(-50%); }
        #rightHandle { right: -10px; top: 50%; transform: translateY(-50%); }
        #controls {
            position: fixed;
            bottom: 20px;
            left: 50%;
            transform: translateX(-50%);
            display: flex;
            gap: 10px;
        }
        button, input[type="file"] {
            padding: 10px 20px;
            font-size: 16px;
            cursor: pointer;
        }
    </style>
</head>
<body>
    <div id="container">
        <canvas id="canvas"></canvas>
        <div id="cropBox">
            <div id="topHandle" class="handle"></div>
            <div id="bottomHandle" class="handle"></div>
            <div id="leftHandle" class="handle"></div>
            <div id="rightHandle" class="handle"></div>
        </div>
    </div>
    <div id="controls">
        <input type="file" id="imageInput" accept="image/*">
        <button onclick="saveCroppedImage()">保存</button>
    </div>
    <script>
        const canvas = document.getElementById('canvas');
        const ctx = canvas.getContext('2d');
        const cropBox = document.getElementById('cropBox');
        const container = document.getElementById('container');
        let image = new Image();
        let imgX = 0, imgY = 0, imgScale = 1;
        let cropX = 0, cropY = 0, cropWidth = 200, cropHeight = 200;
        let isDragging = false, isResizing = false, activeHandle = null;
        let startX, startY, startCropX, startCropY, startCropWidth, startCropHeight;
        let touches = [];
        let lastDistance = 0;

        // 初始化画布大小
        function resizeCanvas() {
            canvas.width = container.clientWidth;
            canvas.height = container.clientHeight;
            updateCropBox();
            drawImage();
        }

        window.addEventListener('resize', resizeCanvas);
        resizeCanvas();

        // 图片加载
        document.getElementById('imageInput').addEventListener('change', (e) => {
            const file = e.target.files[0];
            if (file) {
                const reader = new FileReader();
                reader.onload = (event) => {
                    image.src = event.target.result;
                    image.onload = () => {
                        imgScale = Math.min(canvas.width / image.width, canvas.height / image.height);
                        imgX = (canvas.width - image.width * imgScale) / 2;
                        imgY = (canvas.height - image.height * imgScale) / 2;
                        cropWidth = Math.min(200, image.width * imgScale);
                        cropHeight = Math.min(200, image.height * imgScale);
                        centerCropBox();
                        drawImage();
                    };
                };
                reader.readAsDataURL(file);
            }
        });

        // 绘制图片和裁剪框
        function drawImage() {
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            ctx.drawImage(image, imgX, imgY, image.width * imgScale, image.height * imgScale);
            updateCropBox();
        }

        // 更新裁剪框位置
        function updateCropBox() {
            cropBox.style.left = cropX + 'px';
            cropBox.style.top = cropY + 'px';
            cropBox.style.width = cropWidth + 'px';
            cropBox.style.height = cropHeight + 'px';
        }

        // 裁剪框居中
        function centerCropBox() {
            cropX = (canvas.width - cropWidth) / 2;
            cropY = (canvas.height - cropHeight) / 2;
            updateCropBox();
        }

        // 保存裁剪结果
        function saveCroppedImage() {
            const tempCanvas = document.createElement('canvas');
            tempCanvas.width = cropWidth;
            tempCanvas.height = cropHeight;
            const tempCtx = tempCanvas.getContext('2d');
            const sx = (cropX - imgX) / imgScale;
            const sy = (cropY - imgY) / imgScale;
            const sWidth = cropWidth / imgScale;
            const sHeight = cropHeight / imgScale;
            tempCtx.drawImage(image, sx, sy, sWidth, sHeight, 0, 0, cropWidth, cropHeight);
            
            const link = document.createElement('a');
            link.download = 'cropped_image.png';
            link.href = tempCanvas.toDataURL('image/png');
            link.click();
        }

        // 触摸事件处理
        container.addEventListener('touchstart', (e) => {
            e.preventDefault();
            touches = Array.from(e.touches);
            if (touches.length === 1) {
                const touch = touches[0];
                startX = touch.clientX;
                startY = touch.clientY;
                activeHandle = getActiveHandle(startX, startY);
                if (activeHandle) {
                    isResizing = true;
                    startCropX = cropX;
                    startCropY = cropY;
                    startCropWidth = cropWidth;
                    startCropHeight = cropHeight;
                } else {
                    isDragging = true;
                }
            } else if (touches.length === 2) {
                isDragging = false;
                isResizing = false;
                lastDistance = Math.hypot(
                    touches[0].clientX - touches[1].clientX,
                    touches[0].clientY - touches[1].clientY
                );
            }
        });

        container.addEventListener('touchmove', (e) => {
            e.preventDefault();
            touches = Array.from(e.touches);
            if (touches.length === 1 && isDragging) {
                const touch = touches[0];
                const dx = touch.clientX - startX;
                const dy = touch.clientY - startY;
                imgX += dx;
                imgY += dy;
                startX = touch.clientX;
                startY = touch.clientY;
                drawImage();
            } else if (touches.length === 1 && isResizing) {
                const touch = touches[0];
                const dx = touch.clientX - startX;
                const dy = touch.clientY - startY;
                resizeCropBox(dx, dy);
                drawImage();
            } else if (touches.length === 2) {
                const newDistance = Math.hypot(
                    touches[0].clientX - touches[1].clientX,
                    touches[0].clientY - touches[1].clientY
                );
                const scaleFactor = newDistance / lastDistance;
                const centerX = (touches[0].clientX + touches[1].clientX) / 2;
                const centerY = (touches[0].clientY + touches[1].clientY) / 2;
                
                const prevImgX = imgX;
                const prevImgY = imgY;
                imgScale *= scaleFactor;
                imgX = centerX - (centerX - imgX) * scaleFactor;
                imgY = centerY - (centerY - imgY) * scaleFactor;
                
                lastDistance = newDistance;
                drawImage();
            }
        });

        container.addEventListener('touchend', (e) => {
            touches = Array.from(e.touches);
            if (touches.length === 0 && isResizing) {
                isResizing = false;
                activeHandle = null;
                centerCropBox();
                drawImage();
            }
            if (touches.length === 0) {
                isDragging = false;
            }
        });

        // 判断触摸点是否在裁剪框手柄上
        function getActiveHandle(x, y) {
            const handles = [
                { id: 'topHandle', x: cropX + cropWidth / 2, y: cropY },
                { id: 'bottomHandle', x: cropX + cropWidth / 2, y: cropY + cropHeight },
                { id: 'leftHandle', x: cropX, y: cropY + cropHeight / 2 },
                { id: 'rightHandle', x: cropX + cropWidth, y: cropY + cropHeight / 2 }
            ];
            for (const handle of handles) {
                if (Math.abs(x - handle.x) < 20 && Math.abs(y - handle.y) < 20) {
                    return handle.id;
                }
            }
            return null;
        }

        // 调整裁剪框大小
        function resizeCropBox(dx, dy) {
            if (activeHandle === 'topHandle') {
                cropY = startCropY + dy;
                cropHeight = startCropHeight - dy;
                if (cropHeight < 50) {
                    cropY = startCropY + startCropHeight - 50;
                    cropHeight = 50;
                }
            } else if (activeHandle === 'bottomHandle') {
                cropHeight = startCropHeight + dy;
                if (cropHeight < 50) cropHeight = 50;
            } else if (activeHandle === 'leftHandle') {
                cropX = startCropX + dx;
                cropWidth = startCropWidth - dx;
                if (cropWidth < 50) {
                    cropX = startCropX + startCropWidth - 50;
                    cropWidth = 50;
                }
            } else if (activeHandle === 'rightHandle') {
                cropWidth = startCropWidth + dx;
                if (cropWidth < 50) cropWidth = 50;
            }
            updateCropBox();
        }
    </script>
</body>
</html>