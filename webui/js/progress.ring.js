/* Svg progress ring as custom element. */
/* https://css-tricks.com/building-progress-ring-quickly/ */
class ProgressRing extends HTMLElement {
    constructor() {
        super();
        const stroke = this.getAttribute( 'stroke' ),
            radius = this.getAttribute( 'radius' ),
            normalizedRadius = radius - stroke * 2;
        this._circumference = normalizedRadius * 2 * Math.PI;

        this._root = this.attachShadow( {
            mode: 'open'
        } );
        this._root.innerHTML = `
            <svg
                height="${radius * 2}"
                width="${radius * 2}"
                >
                <circle
                stroke="#eee"
                stroke-dasharray="${this._circumference} ${this._circumference}"
                style="stroke-dashoffset:${this._circumference}"
                stroke-width="${stroke}"
                fill="transparent"
                r="${normalizedRadius}"
                cx="${radius}"
                cy="${radius}"
                />
                <text id="perc" x="50%" y="50%" text-anchor="middle" fill="#eee" dy=".3em">100%</text>
            </svg>

            <style>
                circle {
                    transition: stroke-dashoffset 0.35s;
                    transform: rotate(-90deg);
                    transform-origin: 50% 50%;
                }
                text {
                    text-align: center;
                    font-size: 16px;
                    font-family: "sans-serif"
                }
            </style>
            `;
    }

    setProgress( percent ) {
        const offset = this._circumference - ( percent / 100 * this._circumference ),
            circle = this._root.querySelector( 'circle' );
        circle.style.strokeDashoffset = offset;
    }

    static get observedAttributes() {
        return [ 'progress' ];
    }

    attributeChangedCallback( name, oldValue, newValue ) {
        if ( name === 'progress' ) {
            this.setProgress( newValue );
        }
    }
}

window.customElements.define( 'progress-ring', ProgressRing );

function animateRing( lang ) {
    let progress = 100;
    const el = document.querySelector( 'progress-ring' ),
        perc = el.shadowRoot.querySelector( '#perc' ),
        msg = {
            it: [ 'Istanze ZDL chiuse.', 'Server arrestato.' ],
            en: [ 'ZDL instances closed.', 'Server stopped.' ]
        };

    const interval = setInterval( () => {
        progress -= 5;
        el.setAttribute( 'progress', progress );
        perc.innerHTML = `${progress}%`;
        if ( progress === 0 ) {
            clearInterval( interval );
            perc.innerHTML = `<tspan x="50%" dy=".3">${msg[lang][0]}</tspan>
                              <tspan x="50%" dy="1.5em">${msg[lang][1]}</tspan>`;
        }
    }, 200 );
}
