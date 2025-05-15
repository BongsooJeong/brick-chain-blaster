/**
 * 벽돌 객체 클래스
 */
class Brick {
    /**
     * 벽돌 객체 생성
     * @param {number} x - 벽돌의 x 좌표
     * @param {number} y - 벽돌의 y 좌표
     * @param {number} width - 벽돌의 너비
     * @param {number} height - 벽돌의 높이
     * @param {number} hp - 벽돌의 체력
     * @param {string} color - 벽돌의 색상
     */
    constructor(x, y, width, height, hp = 1, color = '#ff4444') {
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.maxHp = hp;
        this.hp = hp;
        this.color = color;
        this.destroyed = false;
    }

    /**
     * 벽돌 그리기
     * @param {CanvasRenderingContext2D} ctx - 캔버스 컨텍스트
     */
    draw(ctx) {
        if (this.destroyed) return;
        
        // HP에 따른 색상 변화
        const hpRatio = this.hp / this.maxHp;
        const r = parseInt(255 * (1 - hpRatio) + parseInt(this.color.slice(1, 3), 16) * hpRatio);
        const g = parseInt(100 * (1 - hpRatio) + parseInt(this.color.slice(3, 5), 16) * hpRatio);
        const b = parseInt(100 * (1 - hpRatio) + parseInt(this.color.slice(5, 7), 16) * hpRatio);
        
        ctx.beginPath();
        ctx.rect(this.x, this.y, this.width, this.height);
        ctx.fillStyle = `rgb(${r}, ${g}, ${b})`;
        ctx.fill();
        
        // 테두리 그리기
        ctx.strokeStyle = '#ffffff';
        ctx.lineWidth = 2;
        ctx.stroke();
        
        // HP 텍스트 그리기
        if (this.maxHp > 1) {
            ctx.fillStyle = '#ffffff';
            ctx.font = '16px Arial';
            ctx.textAlign = 'center';
            ctx.textBaseline = 'middle';
            ctx.fillText(this.hp.toString(), this.x + this.width / 2, this.y + this.height / 2);
        }
        
        ctx.closePath();
    }

    /**
     * 피해 입히기
     * @param {number} damage - 입힐 피해량
     * @returns {boolean} - 벽돌이 파괴되었는지 여부
     */
    takeDamage(damage = 1) {
        if (this.destroyed) return false;
        
        this.hp -= damage;
        if (this.hp <= 0) {
            this.destroyed = true;
            return true;
        }
        return false;
    }

    /**
     * 볼과의 충돌 검사
     * @param {object} ball - 볼 객체
     * @returns {boolean} - 충돌 여부
     */
    checkCollision(ball) {
        if (this.destroyed || !ball.isActive) return false;
        
        // 볼의 중심점과 벽돌의 가장 가까운 점 계산
        const closestX = Math.max(this.x, Math.min(ball.x, this.x + this.width));
        const closestY = Math.max(this.y, Math.min(ball.y, this.y + this.height));
        
        // 중심점으로부터 거리 계산
        const distanceX = ball.x - closestX;
        const distanceY = ball.y - closestY;
        const distance = Math.sqrt(distanceX * distanceX + distanceY * distanceY);
        
        // 거리가 볼의 반지름보다 작으면 충돌
        if (distance <= ball.radius) {
            // 충돌 방향 결정 및 볼 튕기기
            // 수직/수평 충돌 구분
            const collideHorizontal = closestX === this.x || closestX === this.x + this.width;
            const collideVertical = closestY === this.y || closestY === this.y + this.height;
            
            if (collideHorizontal && collideVertical) {
                // 모서리 충돌: 양쪽 다 반전
                ball.speedX = -ball.speedX;
                ball.speedY = -ball.speedY;
            } else if (collideHorizontal) {
                // 좌우 충돌: x 속도 반전
                ball.speedX = -ball.speedX;
            } else if (collideVertical) {
                // 상하 충돌: y 속도 반전
                ball.speedY = -ball.speedY;
            } else {
                // 벽돌 내부 충돌: 가장 가까운 면으로 튕김
                if (Math.abs(distanceX) < Math.abs(distanceY)) {
                    ball.speedX = -ball.speedX;
                } else {
                    ball.speedY = -ball.speedY;
                }
            }
            
            return true;
        }
        
        return false;
    }
}

// export 처리
export default Brick; 