###Those who don't get Check My Progress Bar automatically in every lab please implement these steps:

First 

## Bookmark Code 

```javascript
javascript:(function () {
    const removeLearboard = document.querySelector('.js-lab-leaderboard');
    const showScore = document.querySelector('.games-labs');

    removeLearboard.remove();
    showScore.className = "lab-show l-full no-nav application-new lab-show l-full no-nav "
})();
```
