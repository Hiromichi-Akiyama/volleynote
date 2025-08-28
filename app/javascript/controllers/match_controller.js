import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "playerSelectionPhase", "startingGrid", "benchGrid",
        "startingCount", "benchCount", "startMatchBtn"
    ]
    
    connect() {
        this.initializeMatchState()
        this.setupEventListeners()
    }

    initializeMatchState() {
        this.matchState = {
            startingPlayers: [],
            benchSelection: []
        }
    }

    setupEventListeners() {
        this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    }

    toggleStartingPlayer(event) {
        const playerId = parseInt(event.currentTarget.dataset.playerId)
        const playerCard = event.currentTarget
        
        if (this.matchState.benchSelection.includes(playerId)) {
            return
        }
        
        const index = this.matchState.startingPlayers.indexOf(playerId)
        
        if (index > -1) {
            this.matchState.startingPlayers.splice(index, 1)
            playerCard.classList.remove('selected')
            playerCard.style.backgroundColor = ''
        } else {
            if (this.matchState.startingPlayers.length >= 6) {
                this.showNotice('スターティングメンバーは最大6名まで選択できます。')
                return
            }
            this.matchState.startingPlayers.push(playerId)
            playerCard.classList.add('selected')
            playerCard.style.backgroundColor = '#d4edda'
        }
        
        this.updateSelectionCounts()
        this.updatePlayerCardStates()
    }

    toggleBenchPlayer(event) {
        const playerId = parseInt(event.currentTarget.dataset.playerId)
        const playerCard = event.currentTarget
        
        if (this.matchState.startingPlayers.includes(playerId)) {
            return
        }
        
        const index = this.matchState.benchSelection.indexOf(playerId)
        
        if (index > -1) {
            this.matchState.benchSelection.splice(index, 1)
            playerCard.classList.remove('selected')
            playerCard.style.backgroundColor = ''
        } else {
            this.matchState.benchSelection.push(playerId)
            playerCard.classList.add('selected')
            playerCard.style.backgroundColor = '#fff3cd'
        }
        
        this.updateSelectionCounts()
        this.updatePlayerCardStates()
    }

    updateSelectionCounts() {
        if (this.hasStartingCountTarget) {
            this.startingCountTarget.textContent = this.matchState.startingPlayers.length
        }
        if (this.hasBenchCountTarget) {
            this.benchCountTarget.textContent = this.matchState.benchSelection.length
        }
        
        if (this.hasStartMatchBtnTarget) {
            this.startMatchBtnTarget.disabled = this.matchState.startingPlayers.length === 0
        }
    }

    updatePlayerCardStates() {
        if (this.hasStartingGridTarget) {
            this.startingGridTarget.querySelectorAll('.player-card').forEach(card => {
                const playerId = parseInt(card.dataset.playerId)
                const isInBench = this.matchState.benchSelection.includes(playerId)
                
                if (isInBench) {
                    card.style.opacity = '0.5'
                    card.style.pointerEvents = 'none'
                } else {
                    card.style.opacity = '1'
                    card.style.pointerEvents = 'auto'
                }
            })
        }
        
        if (this.hasBenchGridTarget) {
            this.benchGridTarget.querySelectorAll('.player-card').forEach(card => {
                const playerId = parseInt(card.dataset.playerId)
                const isStarting = this.matchState.startingPlayers.includes(playerId)
                
                if (isStarting) {
                    card.style.opacity = '0.5'
                    card.style.pointerEvents = 'none'
                } else {
                    card.style.opacity = '1'
                    card.style.pointerEvents = 'auto'
                }
            })
        }
    }

    async startMatch(event) {
        if (this.matchState.startingPlayers.length === 0) {
            this.showNotice('少なくとも1名のスターティングメンバーを選択してください。')
            return
        }

        const matchId = event.target.dataset.matchId
        
        try {
            const response = await fetch(`/matches/${matchId}/start`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': this.csrfToken
                },
                body: JSON.stringify({
                    starting_players: this.matchState.startingPlayers,
                    bench_players: this.matchState.benchSelection
                })
            })
            
            const data = await response.json()
            
            if (data.success) {
                this.showNotice(data.message)
                if (data.redirect_url) {
                    window.location.href = data.redirect_url
                } else {
                    location.reload()
                }
            } else {
                this.showNotice(data.message)
            }
        } catch (error) {
            console.error('Trial start error:', error)
            this.showNotice('試合開始中にエラーが発生しました。')
        }
    }

    // 統計記録機能
    async recordStat(event) {
        const button = event.target
        const playerId = button.dataset.playerId
        const statType = button.dataset.statType
        const delta = parseInt(button.dataset.delta)
        const matchId = button.dataset.matchId
        
        try {
            const response = await fetch(`/matches/${matchId}/record_stat`, {
                method: 'PATCH',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': this.csrfToken
                },
                body: JSON.stringify({
                    player_id: playerId,
                    stat_type: statType,
                    delta: delta
                })
            })
            
            const data = await response.json()
            
            if (data.success) {
                this.updatePlayerStatDisplay(data.player_id, data.stats, data.rates)
            }
        } catch (error) {
            console.error('Stat record error:', error)
        }
    }

    updatePlayerStatDisplay(playerId, stats, rates) {
        const playerRow = document.querySelector(`[data-player-id="${playerId}"]`)
        if (!playerRow) return
        
        // 統計値の更新
        Object.entries(stats).forEach(([statKey, value]) => {
            const statElement = playerRow.querySelector(`[data-stat="${statKey}"]`)
            if (statElement) {
                statElement.textContent = value
            }
        })
        
        // 成功率の更新
        Object.entries(rates).forEach(([rateKey, value]) => {
            const rateElement = playerRow.querySelector(`[data-rate="${rateKey}"]`)
            if (rateElement) {
                rateElement.textContent = `${value}%`
            }
        })
        
        // 視覚的フィードバック
        playerRow.style.backgroundColor = '#d4edda'
        setTimeout(() => {
            playerRow.style.backgroundColor = ''
        }, 300)
    }

    async removePlayer(event) {
        const playerId = event.target.dataset.playerId
        const matchId = event.target.dataset.matchId
        
        if (!confirm('この選手をメンバーから除外しますか？')) {
            return
        }
        
        try {
            const response = await fetch(`/matches/${matchId}/remove_player`, {
                method: 'DELETE',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': this.csrfToken
                },
                body: JSON.stringify({
                    player_id: playerId
                })
            })
            
            const data = await response.json()
            
            if (data.success) {
                this.showNotice(data.message)
                location.reload()
            } else {
                this.showNotice(data.message)
            }
        } catch (error) {
            console.error('Remove player error:', error)
        }
    }

    showNotice(message) {
        const notice = document.getElementById('notice')
        if (notice) {
            notice.textContent = message
            notice.style.display = 'block'
            setTimeout(() => {
                notice.style.display = 'none'
            }, 3000)
        } else {
            alert(message)
        }
    }
}