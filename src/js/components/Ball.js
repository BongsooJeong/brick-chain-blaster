/**
 * 볼 객체 클래스
 */
class Ball {
    /**
     * 볼 객체 생성
     * @param {number} x - 볼의, x 좌표
     * @param {number} y - 볼의 y 좌표
     * @param {number} radius - 볼의 반지름
     * @param {string} color - 볼의 색상
     */
    constructor(x, y, radius, color = '#ffffff') {
        this.x = x;
        this.y = y;
        this.radius = radius;
        this.color = color;
        this.speedX = 0;
        this.speedY = 0;
        this.isActive = false;
    }

    /**
     * 볼 발사
     * @param {number} angle - 발사 각도 (라디안)
     * @param {number} power - 발사 속도
     */
    launch(angle, power) {
        this.speedX = Math.cos(angle) * power;
        this.speedY = Math.sin(angle) * power;
        this.isActive = true;
    }

    /**
     * 볼 위치 업데이트
     */
    update() {
        if (!this.isActive) return;
        
        this.x += this.speedX;
        this.y += this.speedY;
    }

    /**
     * 볼 그리기
     * @param {CanvasRenderingContext2D} ctx - 캔버스 컨텍스트
     */
    draw(ctx) {
        ctx.beginPath();
        ctx.arc(this.x, this.y, this.radius, 0, Math.PI * 2);
        ctx.fillStyle = this.color;
        ctx.fill();
        ctx.closePath();
    }

    /**
     * 벽과의 충돌 검사 및 튕김 처리
     * @param {number} canvasWidth - 캔버스 너비
     * @param {number} canvasHeight - 캔버스 높이
     * @returns {boolean} - 바닥에 닿았는지 여부
     */
    checkWallCollision(canvasWidth, canvasHeight) {
        let hitBottom = false;
        
        // 좌우 벽 충돌
        if (this.x - this.radius <= 0 || this.x + this.radius >= canvasWidth) {
            this.speedX = -this.speedX;
            // 벽 안으로 들어가지 않도록 위치 조정
            if (this.x - this.radius <= 0) {
                this.x = this.radius;
            } else {
                this.x = canvasWidth - this.radius;
            }
        }
        
        // 상단 벽 충돌
        if (this.y - this.radius <= 0) {
            this.speedY = -this.speedY;
            this.y = this.radius;
        }
        
        // 바닥 충돌
        if (this.y + this.radius >= canvasHeight) {
            this.isActive = false;
            hitBottom = true;
        }
        
        return hitBottom;
    }
}

// export 처리
export default Ball; 