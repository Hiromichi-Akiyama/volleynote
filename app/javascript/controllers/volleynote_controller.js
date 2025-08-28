import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["playerGrid", "courtGrid", "benchGrid", "matchTable"]
    
    connect() {
        this.initializeMatchState()
    }

    initializeMatchState() {
        this.matchState = {
            isActive: false,
            startingPlayers: [],
            benchSelection: [],
            courtPlayers: [],
            benchPlayers: [],
            substitutionMode: false,
            substitutingPlayer: null,
            modalMode: '',
            matchStartStats: {},
            participatedPlayers: []
        }
    }

    async bumpStat(event) {
        const playerId = event.target.dataset.playerId
        const statKey = event.target.dataset.statKey
        const delta = parseInt(event.target.dataset.delta)
        
        try {
            const response = await fetch(`/players/${playerId}/bump_stat`, {
                method: 'PATCH',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': window.csrfToken
                },
                body: JSON.stringify({
                    stat_key: statKey,
                    delta: delta
                })
            })
            
            if (response.ok) {
                const data = await response.json()
                this.updateStatDisplay(playerId, statKey, data.new_value, data.rates)
            }
        } catch (error) {
            console.error('Stat update error:', error)
        }
    }

    updateStatDisplay(playerId, statKey, newValue, rates) {
        const valueElement = document.querySelector(`[data-stat="${statKey}"]`)
        if (valueElement) {
            valueElement.textContent = newValue
            
            // 視覚的フィードバック
            valueElement.style.backgroundColor = '#d4edda'
            setTimeout(() => {
                valueElement.style.backgroundColor = ''
            }, 300)
        }
        
        // 成功率の更新
        if (rates) {
            Object.entries(rates).forEach(([rateKey, rateValue]) => {
                const rateElement = document.querySelector(`[data-rate="${rateKey}"]`)
                if (rateElement) {
                    rateElement.textContent = `${rateValue.toFixed(1)}%`
                }
            })
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
        }
    }
}