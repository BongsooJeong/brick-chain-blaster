import Ball from './js/components/Ball.js';
import Brick from './js/components/Brick.js';

// 게임 캔버스 설정
const canvas = document.getElementById('game-canvas');
const ctx = canvas.getContext('2d');

// 캔버스 크기 설정
function resizeCanvas() {
    const container = document.getElementById('game-container');
    canvas.width = container.clientWidth;
    canvas.height = container.clientHeight;
}

// 초기 리사이즈 및 리사이즈 이벤트 리스너 추가
resizeCanvas();
window.addEventListener('resize', resizeCanvas);

// 게임 객체
const game = {
    // 게임 상태
    state: 'init', // 'init', 'playing', 'paused', 'gameOver'
    score: 0,
    balls: [],
    bricks: [],
    ballRadius: 10,
    ballSpeed: 5,
    brickRows: 5,
    brickCols: 8,
    brickPadding: 10,
    brickOffsetTop: 50,
    brickOffsetLeft: 30,
    
    // 게임 초기화
    init() {
        this.state = 'init';
        this.score = 0;
        this.balls = [];
        this.bricks = [];
        
        // 공 생성
        const ball = new Ball(
            canvas.width / 2, 
            canvas.height - 30, 
            this.ballRadius
        );
        this.balls.push(ball);
        
        // 벽돌 생성
        this.createBricks();
        
        this.startGame();
    },
    
    // 벽돌 생성
    createBricks() {
        const brickWidth = (canvas.width - this.brickOffsetLeft * 2 - this.brickPadding * (this.brickCols - 1)) / this.brickCols;
        const brickHeight = 30;
        
        for (let row = 0; row < this.brickRows; row++) {
            for (let col = 0; col < this.brickCols; col++) {
                const brickX = col * (brickWidth + this.brickPadding) + this.brickOffsetLeft;
                const brickY = row * (brickHeight + this.brickPadding) + this.brickOffsetTop;
                
                // HP는 행에 따라 증가
                const hp = row + 1;
                
                // 색상도 HP에 따라 다르게
                let color;
                switch (hp) {
                    case 1: color = '#ff4444'; break; // 빨간색
                    case 2: color = '#44ff44'; break; // 녹색
                    case 3: color = '#4444ff'; break; // 파란색
                    case 4: color = '#ffff44'; break; // 노란색
                    case 5: color = '#ff44ff'; break; // 보라색
                    default: color = '#ffffff'; break; // 흰색
                }
                
                const brick = new Brick(brickX, brickY, brickWidth, brickHeight, hp, color);
                this.bricks.push(brick);
            }
        }
    },
    
    // 게임 시작
    startGame() {
        this.state = 'playing';
        this.update();
    },
    
    // 게임 일시 정지
    pauseGame() {
        if (this.state === 'playing') {
            this.state = 'paused';
        } else if (this.state === 'paused') {
            this.state = 'playing';
            this.update();
        }
    },
    
    // 게임 업데이트 (게임 루프)
    update() {
        if (this.state !== 'playing') return;
        
        // 화면 지우기
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        
        // 볼 업데이트 및 충돌 확인
        this.updateBalls();
        
        // 게임 요소 그리기
        this.draw();
        
        // 다음 프레임 요청
        requestAnimationFrame(() => this.update());
    },
    
    // 볼 업데이트 및 충돌 확인
    updateBalls() {
        let allBallsInactive = true;
        
        for (const ball of this.balls) {
            if (!ball.isActive) continue;
            
            allBallsInactive = false;
            
            // 볼 위치 업데이트
            ball.update();
            
            // 벽 충돌 검사
            const hitBottom = ball.checkWallCollision(canvas.width, canvas.height);
            
            // 벽돌 충돌 검사
            for (const brick of this.bricks) {
                if (brick.checkCollision(ball)) {
                    // 충돌 효과 (점수 증가 등)
                    if (brick.takeDamage()) {
                        this.score += brick.maxHp * 10;
                    }
                }
            }
        }
        
        // 모든 볼이 비활성 상태인 경우 (게임 오버 또는 턴 종료)
        if (allBallsInactive && this.balls.length > 0) {
            // 게임 재시작 또는 다음 턴 처리
            this.prepareNextTurn();
        }
        
        // 모든 벽돌이 파괴된 경우
        if (this.bricks.every(brick => brick.destroyed)) {
            // 다음 레벨 처리
            this.nextLevel();
        }
    },
    
    // 다음 턴 준비
    prepareNextTurn() {
        // 볼 재배치
        for (const ball of this.balls) {
            ball.x = canvas.width / 2;
            ball.y = canvas.height - 30;
            ball.speedX = 0;
            ball.speedY = 0;
            ball.isActive = false;
        }
        
        // 첫 번째 볼 활성화 (나중에 발사)
        if (this.balls.length > 0) {
            // 자동 발사 대신 클릭 발사로 변경
            canvas.addEventListener('click', this.handleClick.bind(this), { once: true });
        }
    },
    
    // 클릭 핸들러
    handleClick(event) {
        if (this.state !== 'playing' || this.balls.length === 0) return;
        
        const ball = this.balls[0];
        if (ball.isActive) return;
        
        // 클릭 위치 계산
        const rect = canvas.getBoundingClientRect();
        const clickX = event.clientX - rect.left;
        const clickY = event.clientY - rect.top;
        
        // 발사 각도 계산 (공에서 클릭 위치로의 방향)
        const dx = clickX - ball.x;
        const dy = clickY - ball.y;
        const angle = Math.atan2(dy, dx);
        
        // 공 발사
        ball.launch(angle, this.ballSpeed);
    },
    
    // 다음 레벨로 진행
    nextLevel() {
        // 점수 보너스
        this.score += 1000;
        
        // 벽돌 재생성 (더 많은 HP로)
        this.bricks = [];
        this.brickRows = Math.min(this.brickRows + 1, 8); // 최대 8행
        this.createBricks();
        
        // 턴 준비
        this.prepareNextTurn();
    },
    
    // 게임 화면 그리기
    draw() {
        // 볼 그리기
        for (const ball of this.balls) {
            ball.draw(ctx);
        }
        
        // 벽돌 그리기
        for (const brick of this.bricks) {
            brick.draw(ctx);
        }
        
        // UI 그리기
        this.drawUI();
    },
    
    // UI 그리기
    drawUI() {
        // 점수 표시
        ctx.fillStyle = '#ffffff';
        ctx.font = '20px Arial';
        ctx.textAlign = 'left';
        ctx.fillText(`Score: ${this.score}`, 20, 30);
        
        // 게임 상태 표시
        if (this.state === 'paused') {
            ctx.font = '30px Arial';
            ctx.textAlign = 'center';
            ctx.fillText('PAUSED', canvas.width / 2, canvas.height / 2);
            ctx.font = '20px Arial';
            ctx.fillText('Press P to continue', canvas.width / 2, canvas.height / 2 + 40);
        }
        
        // 게임 시작 안내 (첫 턴)
        if (this.state === 'playing' && this.balls.length > 0 && !this.balls[0].isActive) {
            ctx.font = '20px Arial';
            ctx.textAlign = 'center';
            ctx.fillText('Click to launch ball', canvas.width / 2, canvas.height - 60);
        }
    }
};

// 키보드 이벤트 리스너
window.addEventListener('keydown', (e) => {
    if (e.key === 'p' || e.key === 'P') {
        game.pauseGame();
    }
});

// 게임 초기화
document.addEventListener('DOMContentLoaded', () => {
    game.init();
}); 