//import Foundation
//import Tagged
//
//extension Recipe {
//  static let giantMock = Recipe(
//    id: .init(),
//    name: "Double Cheese Burger",
//    imageData: [
//      .init(
//        id: .init(),
//        data: (try? Data(contentsOf: Bundle.main.url(forResource: "recipe_00", withExtension: "jpeg")!))!
//      )!,
//      .init(
//        id: .init(),
//        data: (try? Data(contentsOf: Bundle.main.url(forResource: "recipe_01", withExtension: "jpeg")!))!
//      )!,
//      .init(
//        id: .init(),
//        data: (try? Data(contentsOf: Bundle.main.url(forResource: "recipe_02", withExtension: "jpeg")!))!
//      )!,
//    ],
//    aboutSections: [
//      .init(
//        id: .init(),
//        name: "Description",
//        description: """
//A proper meat feast, this classical burger is just too good! It's a culinary masterpiece that brings together a symphony of flavors and textures in every bite. Imagine sinking your teeth into a burger that's beyond your wildest dreams - a tantalizing creation that elevates your taste buds to a whole new level of ecstasy.
//
//Let's start with the foundation - the homemade buns. These delightful pillows of goodness are crafted with love and precision. The dough, made with the finest ingredients, is skillfully kneaded until it reaches the perfect consistency - soft, yet resilient. As it rises, the kitchen is filled with the irresistible aroma of fresh-baked bread, enticing everyone within its vicinity.
//
//Now, let's move on to the star of the show - the succulent ground meat. This is no ordinary patty; it's a carefully crafted work of art. The beef, sourced from trusted farmers, is a symphony of flavors that burst in your mouth with each bite. The seasonings, a secret blend of spices, add a tantalizing complexity that keeps you guessing with every mouthful. Cooked to perfection on a sizzling grill, the patty gains a delightful char that seals in all its juiciness.
//
//As the burger comes together, you can't help but marvel at the harmonious balance of flavors. The melted cheese, oozing like liquid gold, adds a creamy richness that complements the savory beef. Fresh lettuce, crispy and green, provides a refreshing crunch that balances the meat's hearty richness. Slices of ripe tomatoes bring a burst of juiciness and sweetness, while the tangy pickles add a delightful zing that awakens your taste buds.
//
//But we're not done yet. The crowning glory of this masterpiece is the secret sauce - a blend of carefully selected ingredients that create a symphony of flavors in your mouth. Creamy yet tangy, this sauce ties all the elements of the burger together, creating a culinary experience that leaves you speechless.
//
//Serving this burger is an event in itself. As you lift it to your lips, you can feel the anticipation building inside you. The first bite is an explosion of flavors - the softness of the bun, the juiciness of the patty, the creaminess of the cheese, the crunch of the lettuce, the burst of tomatoes, and the zing of the pickles. It's a party in your mouth, a dance of flavors that leaves you in awe.
//
//This burger is more than just food; it's an experience. It's a moment of joy, a celebration of good taste and culinary artistry. Whether enjoyed in the comfort of your home or at a lively cookout with friends, this burger will forever hold a special place in your heart.
//
//So, next time you're craving a burger, don't settle for the ordinary. Treat yourself to this extraordinary creation, and embark on a culinary journey that will delight your senses and leave you yearning for more. This classical burger is more than just a meal; it's a culinary adventure that you won't soon forget. It's time to elevate your burger game and savor the magic of this delectable masterpiece.
//"""
//      ),
//      .init(
//        id: .init(),
//        name: "Do I Really Need To Make Homemade Bread?",
//        description: """
//Of course not, there are great products in the store. But what's the fun in that? Making homemade bread is a delightful journey that takes you on an exploration of flavors, aromas, and textures like no other. It's an experience that transcends the mere act of baking; it's a culinary adventure that opens up a world of creativity and satisfaction.
//
//Imagine stepping into your kitchen, armed with a bag of flour, a packet of yeast, and the excitement of a curious explorer. As you begin to mix the ingredients, the kitchen becomes a canvas for your imagination. The soft powdery flour transforms into a pliable dough under your hands, and the transformation fills you with a sense of wonder and accomplishment.
//
//Kneading the dough is an art form in itself - a rhythmic dance between your hands and the dough that creates a magical connection. With each press, fold, and turn, the dough takes on a new texture, becoming smoother and more elastic. The repetitive motion is meditative, calming your mind and allowing you to be present in the moment.
//
//As the dough rises, the kitchen fills with the intoxicating aroma of yeast at work. The anticipation builds, and you can't help but peek into the bowl to witness the dough doubling in size. It's a moment of joy and satisfaction, knowing that you've nurtured this living organism and brought it to life.
//
//The act of shaping the dough is an opportunity to unleash your creativity. You can craft it into a traditional loaf, a rustic boule, or playful rolls that evoke a sense of whimsy. Each shape tells a story, and as you place them on the baking sheet, you feel a sense of pride in the beautiful creations you've made.
//
//But it's not just the process that makes homemade bread special; it's the taste and texture that set it apart from store-bought alternatives. The first bite is a revelation - the crust crackles as you break through it, revealing the tender crumb inside. The flavor is unmatched - a symphony of nutty, slightly sweet notes that dance on your taste buds.
//
//As you savor the bread, you can't help but marvel at the fact that you created this from scratch. It's a reminder of your culinary prowess and a testament to the joy of creating something with your own hands. The satisfaction you feel goes beyond the taste; it's the knowledge that you've taken a handful of simple ingredients and transformed them into a masterpiece.
//
//And let's not forget the joy of sharing homemade bread with loved ones. The act of breaking bread together creates a sense of connection and community. Whether it's a family dinner or a gathering of friends, the bread becomes a centerpiece that brings people together, sparking conversations and creating lasting memories.
//
//So, while you don't necessarily "need" to make homemade bread, the experience of doing so is a treasure trove of joy and fulfillment. It's a journey that nourishes not only your body but also your soul. It's an invitation to slow down, be present, and savor the simple pleasures of life. The fun in making homemade bread lies in the process, the sense of achievement, and the sheer joy of indulging in the fruits of your labor. So, why not embark on this culinary adventure and discover the magic of homemade bread for yourself? Your taste buds and your heart will thank you for it.
//"""
//      ),
//      .init(
//        id: .init(),
//        name: "Possible Improvements",
//        description: """
//I think burgers need sweet toppings. I think some bacon onion jam, bbq sauce, and even fried onions would make this burger over the top good. Chargrilling these burgers will also make a world of difference. If you can't do that, than a smash patty is the best alternative. Make sure the pan is super ultra mega hot first!"
//
//When it comes to burgers, the possibilities for improvement are as vast as the culinary universe itself. With each delectable suggestion, the flavors of this already divine creation are elevated to dizzying heights, creating a symphony of tastes that will dance on your taste buds like never before.
//
//Let's start with the notion of sweet toppings. The concept of balancing the savory richness of the beef patty with a touch of sweetness is pure brilliance. Imagine a luscious bacon onion jam, caramelized to perfection, releasing its velvety sweetness with every bite. The burst of flavors that follow is an exploration of taste, where the savory notes of the patty meet the silky sweetness of the jam in a dance of culinary delight.
//
//And let's not forget the smoky allure of BBQ sauce. Picture the tangy, smoky sauce slathered generously on the patty, adding a layer of complexity that sets your taste buds alight with excitement. The marriage of smokiness with the succulence of the burger is a match made in culinary heaven, a match that will leave you craving more.
//
//And what about the temptation of fried onions? The crisp, golden rings of onion, fried to a perfect crunch, impart a texture that elevates the burger to a whole new level of enjoyment. Each bite is a delightful contrast of textures - the tender patty, the pillowy bun, and the crunchy onion rings that add a delightful surprise to every mouthful.
//
//But the magic doesn't end there. Let's talk about chargrilling these burgers. The thought of the sizzling patties on a hot grill, leaving tantalizing char marks that speak of smoky goodness, is enough to make your mouth water with anticipation. The smoky aroma that fills the air is a prelude to the culinary symphony about to unfold in your mouth.
//
//For those who may not have access to a grill, fear not - the genius of the smash patty comes to the rescue. The technique of smashing the patties on a searing hot pan is a game-changer. The intense heat locks in the juiciness, creating a patty that is irresistibly tender and flavorful. The sizzle that greets you as the patty hits the pan is music to your ears, and the sight of the caramelized crust forming on the meat is pure artistry.
//
//But remember, with great power comes great responsibility. To achieve the perfect smash patty, the pan must be super ultra mega hot - an inferno that transforms the meat into a culinary masterpiece. The searing heat is the key to achieving that mouthwatering crust that seals in the juices, ensuring every bite is a burst of succulence.
//
//In the world of burgers, innovation knows no bounds. The art of topping and grilling is a playground for culinary adventurers like you. So, the next time you embark on the journey of burger perfection, don't be afraid to explore the realm of sweet toppings, smoky BBQ sauce, crispy fried onions, and the wonders of chargrilling or the smash patty technique. Each improvement is a revelation, an opportunity to create a burger experience that transcends the ordinary and ventures into the realm of extraordinary.
//
//As you take that first bite, the symphony of flavors will unfold before you, and you will savor each note as if it were a precious gift. Your taste buds will sing with joy, and the joy of creation will fill your heart. This is the magic of culinary innovation - the power to transform a classic into a legend, a simple burger into a work of art. So, embrace the world of possibilities, and let your creativity shine as you elevate the burger experience to a whole new dimension of deliciousness. Bon appétit!
//"""
//      ),
//    ],
//    ingredientSections: [
//      .init(
//        id: .init(),
//        name: "Buns",
//        ingredients: [
//          .init(id: .init(), name: "Flour", amount: 2, measure: "cups"),
//          .init(id: .init(), name: "Instant Yeast", amount: 2, measure: "tbsp"),
//          .init(id: .init(), name: "Salt", amount: 2, measure: "tsp"),
//          .init(id: .init(), name: "Sugar", amount: 2, measure: "tbsp"),
//          .init(id: .init(), name: "Butter", amount: 2, measure: "stick"),
//          .init(id: .init(), name: "Water", amount: 2, measure: "cups"),
//        ]
//      ),
//      .init(
//        id: .init(),
//        name: "Patties",
//        ingredients: [
//          .init(id: .init(), name: "Beef Chuck", amount: 8, measure: "oz"),
//          .init(id: .init(), name: "Beef Fat Trimmings or Beef Bone Marrow", amount: 2, measure: "oz")
//        ]
//      ),
//      .init(
//        id: .init(),
//        name: "Toppings",
//        ingredients: [
//          .init(id: .init(), name: "Lettuce", amount: 2, measure: "leaves"),
//          .init(id: .init(), name: "Tomato", amount: 2, measure: "thick slices"),
//          .init(id: .init(), name: "Onion", amount: 2, measure: "thick slices"),
//          .init(id: .init(), name: "Pickle", amount: 2, measure: "chips"),
//          .init(id: .init(), name: "Ketchup", amount: 2, measure: "tbsp"),
//          .init(id: .init(), name: "Mustard", amount: 2, measure: "tbsp")
//        ]
//      ),
//      .init(
//        id: .init(),
//        name: "Homemade Ketchup",
//        ingredients: [
//          .init(id: .init(), name: "Tomato Paste", amount: 1, measure: "cup"),
//          .init(id: .init(), name: "White Vinegar", amount: 1/2, measure: "cup"),
//          .init(id: .init(), name: "Granulated Sugar", amount: 1/4, measure: "cup"),
//          .init(id: .init(), name: "Salt", amount: 1/2, measure: "tsp"),
//          .init(id: .init(), name: "Onion Powder", amount: 1/4, measure: "tsp"),
//          .init(id: .init(), name: "Garlic Powder", amount: 1/4, measure: "tsp"),
//          .init(id: .init(), name: "Ground Mustard", amount: 1/4, measure: "tsp"),
//          .init(id: .init(), name: "Ground Cloves", amount: 1/8, measure: "tsp"),
//          .init(id: .init(), name: "Water", amount: 1/4, measure: "cup")
//        ]
//      ),
//      .init(
//        id: .init(),
//        name: "Homemade Yellow Mustard",
//        ingredients: [
//          .init(id: .init(), name: "Yellow Mustard Seeds", amount: 1/4, measure: "cup"),
//          .init(id: .init(), name: "Brown Mustard Seeds", amount: 1/4, measure: "cup"),
//          .init(id: .init(), name: "Apple Cider Vinegar", amount: 1/2, measure: "cup"),
//          .init(id: .init(), name: "Water", amount: 1/2, measure: "cup"),
//          .init(id: .init(), name: "Honey", amount: 1/4, measure: "cup"),
//          .init(id: .init(), name: "Salt", amount: 1/2, measure: "tsp"),
//          .init(id: .init(), name: "Turmeric", amount: 1/4, measure: "tsp"),
//          .init(id: .init(), name: "Garlic Powder", amount: 1/4, measure: "tsp"),
//          .init(id: .init(), name: "Onion Powder", amount: 1/4, measure: "tsp"),
//          .init(id: .init(), name: "Ground Paprika", amount: 1/8, measure: "tsp"),
//        ]
//      ),
//    ],
//    stepSections: [
//      .init(id: .init(), name: "Buns", steps: [
//        .init(
//          id: .init(),
//          description: """
//In the artful dance of creating culinary wonders, let us embark on the first step of this divine process. With a grace that rivals a ballet dancer, we bring together the essential ingredients into the welcoming embrace of a stand-mixer bowl. Here, the symphony of flavors begins to take shape, each element contributing its unique voice to the harmonious ensemble.
//
//As the mixer whirs to life, it delicately embraces the ingredients, coaxing them into a delightful duet. With each turn of the beaters, the elements intertwine, their flavors mingling and merging into a crescendo of taste. It is a dance of textures too, with the smoothness of some ingredients blending seamlessly with the delightful crunch of others.
//
//With unwavering patience, we allow the mixer to knead the ensemble for ten minutes - a period of time that transcends the mundane, as the stand-mixer works its magic. It is a mesmerizing sight to behold, watching as the dough evolves, transforming from a humble gathering of ingredients into a cohesive and supple masterpiece.
//
//Like a seasoned conductor leading an orchestra, we observe the dough's progress. The once disjointed notes now play in perfect harmony, forming a symphony of flavors and textures that is a delight to the senses. The dough becomes taut and elastic under the mixer's gentle touch, promising a final creation that is nothing short of perfection.
//
//As the ten minutes draw to a close, we marvel at the dough's transformation. Its surface glistens like a starlit night, reflecting the care and attention poured into its creation. The moment is one of sheer culinary artistry, a testament to the magic that unfolds when the right ingredients come together in harmony.
//
//With this first step completed, we stand in awe of the dough's magnificence. But this is just the beginning - there are still more acts in this culinary symphony, each promising delights beyond compare. So, we savor the moment, knowing that what lies ahead is a culinary journey of epic proportions. With the dough now ready, we eagerly await the next steps that will bring us closer to the final masterpiece - a gastronomic triumph that will be savored with every bite.
//""",
//          imageData: [.init(id: .init(), data: (try? Data(contentsOf: Bundle.main.url(forResource: "burger_bun_01", withExtension: "jpg")!))!)! ]
//        ),
//        .init(
//          id: .init(),
//          description: """
//With the precision of a master artisan, we move on to the next act in this culinary symphony. Having lovingly kneaded the dough to perfection, we now cradle it in a tender embrace, placing it gently into a bowl that serves as its cocoon of transformation. This bowl becomes a sanctuary, a haven of warmth and nurturing, where the magic of rising unfolds.
//
//Like a conductor guiding an orchestra, we ensure that the bowl is covered, cradling the dough with a protective shield that allows it to rest and blossom. In this cocoon, the dough is surrounded by an ambiance of tranquility, a moderately warm embrace ranging between 70F and 80F. It is in this gentle climate that the dough will undergo its metamorphosis, evolving into a wondrous creation that will astound and delight.
//
//As we wait, time itself seems to slow down, every minute feeling like an eternity, yet also fleeting in its passage. The aroma of the dough fills the air, promising delights to come. We watch with anticipation, knowing that something magical is happening beneath that cover, hidden from our view.
//
//And then, the moment arrives - the dough begins to stir, as if awakening from a peaceful slumber. It rises, gradually and gracefully, stretching its delicate strands and expanding in size. It is a mesmerizing sight, akin to watching a flower bloom in slow motion, or witnessing the birth of a star.
//
//The dough, now doubled in size, is a sight to behold. It is a testament to the alchemy of baking, a transformation that only time and patience can achieve. With every passing minute, it becomes more than just dough - it is a manifestation of our culinary dreams, a creation that defies the ordinary.
//
//In this journey of rising, we see not just a dough's expansion, but the evolution of our craft. It is a moment of revelation, where we witness the beauty of the baking process in all its glory. It reminds us that great things take time, that patience and nurturing are the keys to unlocking extraordinary flavors and textures.
//
//As we tenderly uncover the bowl, we are greeted by a sight that fills us with pride and joy. The dough, once a humble mixture of ingredients, has blossomed into a work of art. It is a canvas waiting to be painted with flavors, a blank slate that will become a canvas for our culinary creativity.
//
//With the rising complete, we know that this is not the end of the journey, but merely a prelude to what lies ahead. The dough, now transformed, holds the promise of so much more. It is ready to be shaped, molded, and guided into its final form - a culinary masterpiece that will captivate the senses and leave a lasting impression.
//
//And so, with the rising complete, we take a moment to savor this milestone, knowing that what comes next will be a symphony of taste and textures, a creation that will bring joy and delight to those who have the privilege to savor it. As we move forward, we carry with us the memory of the rising - a moment of wonder and magic that reminds us of the artistry of baking and the beauty of culinary creation.
//""",
//          imageData: [.init(id: .init(), data: (try? Data(contentsOf: Bundle.main.url(forResource: "burger_bun_02", withExtension: "jpg")!))!)! ]
//        ),
//        .init(
//          id: .init(),
//          description: """
//In this act of culinary finesse, we find ourselves at a pivotal moment in the creation of our doughy masterpiece. The dough, having gracefully risen to new heights, is now ready for the next step of its metamorphosis. But first, with the gentlest touch, we gently pound the gas out of the dough, as if waking it from a contented slumber.
//
//As we knead the dough once again, we feel a connection to this living, breathing creation. Our hands work with a tenderness that belies the strength required, coaxing the dough back into a large, cohesive ball. It is a moment of transformation, as the dough's elasticity responds to our touch, yielding to our guidance.
//
//With the dough now re-kneaded and unified, we embark on a delightful dance of artistry. Like a sculptor shaping clay into exquisite forms, we take small portions of the dough and deftly roll them into delicate balls. Each one is lovingly crafted, their contours shaped by the careful pressing and pinching of our fingers.
//
//As we step back to admire our handiwork, the dough balls rest under a veil of protection. They are covered, shielded from the outside world, as they embark on their own journey of rising. In this cocoon of warmth, the dough balls are given the time they need to double in size, to evolve into ethereal delights that will enchant the palate.
//
//We, too, wait with anticipation, knowing that this period of rising is an essential part of the dough's maturation. As the dough balls rest, time becomes a symphony of flavors and textures in its own right. It is a symphony that requires patience and trust, a testament to the art of baking that has been passed down through generations.
//
//As we uncover the dough balls after their transformation, we witness their triumphant growth. They have doubled in size, a testament to the alchemy of rising. The once humble portions of dough now stand tall and proud, their surfaces adorned with a delicate sheen that glimmers like morning dew.
//
//It is a moment of pride, knowing that our skill and dedication have yielded such results. But this is not the end of their journey; it is merely a prelude to what lies ahead. The dough balls are now poised to become the stars of the culinary stage, taking center stage in a performance of taste and aroma.
//
//With the rising complete, we are filled with a sense of fulfillment and excitement. The dough balls have blossomed, ready to be shaped into culinary delights that will leave a lasting impression. Each one is a masterpiece in its own right, a testament to the artistry of baking and the joy of creation.
//
//As we proceed to the next steps, we carry with us the memory of the rising - a moment of transformation and wonder. With every movement of our hands and every decision we make, we know that we are shaping not only dough but the very essence of culinary artistry. The journey continues, and we eagerly anticipate the delights that await.
//
//"""
//          imageData: [.init(id: .init(), data: (try? Data(contentsOf: Bundle.main.url(forResource: "burger_bun_03", withExtension: "jpg")!))!)! ]
//        ),
//        .init(
//          id: .init(),
//          description: """
//In this enchanting chapter of our culinary odyssey, we arrive at a moment of triumph - the culmination of the dough balls' journey of rising. Like eager spectators witnessing a grand spectacle, we uncover the dough balls, revealing their magnificent transformation. They have risen accordingly, having doubled in size, and now stand as a testament to the magic of baking.
//
//With great care and finesse, we turn our attention to elevating these dough balls to new heights of flavor. We delicately season them with a sprinkling of salt and sesame seeds, a symphony of savory and nutty notes that will dance upon the taste buds. The salt adds a touch of depth, enhancing the dough balls' natural richness, while the sesame seeds lend a delightful crunch, like tiny jewels adorning the surface.
//
//As we place the seasoned dough balls into the warmth of the oven, the air becomes suffused with the aroma of anticipation. The heat becomes a caress, embracing the dough balls with a gentle warmth that promises transformation. The oven becomes a magical realm, where alchemy takes place, and humble ingredients become culinary delights.
//
//At precisely 450F, the oven becomes a maestro, conducting a symphony of heat. Time becomes a conductor's baton, guiding the dough balls through their metamorphosis. We eagerly await the crescendo - the moment when the dough balls reach their crescendo of perfection.
//
//With each passing minute, the oven's heat works its magic. The dough balls undergo a metamorphosis, their textures evolving from supple softness to golden allure. The outside develops a beguiling crispness, a delicate shell that protects the tender interior.
//
//As the minutes tick by, we remain vigilant, using every sense to gauge the dough balls' readiness. We listen for the telltale crackle and sizzle, a symphony of sound that signals their culinary awakening. We watch with anticipation, observing their transformation from mere dough to culinary masterpieces.
//
//And then, the moment arrives - the dough balls emerge from the oven, resplendent in their golden glory. Their surfaces glisten like the morning sun, promising delights beyond compare. But there is one final test to ensure their perfection - an internal temperature of 190F.
//
//With bated breath, we employ our culinary intuition, trusting our senses to guide us. The moment the thermometer registers 190F, we know that our creation is complete. It is a moment of triumph, knowing that we have achieved perfection in the art of baking.
//
//As we bask in the glow of our accomplishment, we know that this is not just the end of a chapter, but the beginning of a new one. The seasoned and baked dough balls are now stars in their own right, ready to take center stage on the culinary canvas.
//
//In this chapter of the culinary saga, we have witnessed the magic of rising, seasoned with care and transformed by the heat of the oven. With every step, we have honed our craft and embraced the joy of creation. As we move forward, we carry with us the memory of this triumphant chapter, a reminder of the artistry of baking and the wonders that await in the kitchen.
//""",
//          imageData: [.init(id: .init(), data: (try? Data(contentsOf: Bundle.main.url(forResource: "burger_bun_04", withExtension: "jpg")!))!)! ]
//        ),
//        .init(
//          id: .init(),
//          description: """
//After the baking process is complete, we embark on the next crucial step in the journey of our delectable buns. With a gentle touch, we release them from the confinement of the loaf pan, setting them free on a cooling rack. This act is not just a simple transfer; it is a moment of culinary wisdom. By placing the buns on the cooling rack, we ensure that the steam can escape, preventing the dough from becoming soggy and preserving their pristine texture.
//
//As the buns rest on the cooling rack, a tantalizing aroma fills the air. It is the aroma of satisfaction, a testament to the artistry of baking that we have mastered. But there is one more act of indulgence that awaits - basting the buns with the silky goodness of butter.
//
//With a generous hand, we lovingly apply the butter to each bun, like an artist applying brush strokes to a canvas. The butter glistens like liquid gold, adding a luxurious touch to our creation. It is a moment of indulgence, an offering of decadence that will elevate the buns to new heights of flavor.
//
//And now, the buns rest, as if savoring the final act of their transformation. They have earned this respite, having journeyed through the heat of the oven and emerged as golden beauties. As we patiently wait for the timer to tick away, we know that this moment of rest is essential. It allows the flavors to meld, the textures to settle, and the essence of our creation to reach its full potential.
//
//With each passing minute, the anticipation grows, like the crescendo of a symphony building to its climax. And then, the time has come - the buns have completed their rest, and we stand ready to savor the fruits of our labor.
//
//As we slice into the buns, a chorus of delight arises. The knife glides effortlessly through the tender crumb, revealing a beautifully golden interior. The buttery sheen beckons, and with each bite, we are transported to a realm of gastronomic pleasure.
//
//The buns, like stars on a celestial stage, have taken center stage in a culinary performance that leaves us in awe. It is a moment of gratification, knowing that our dedication to the craft has yielded a masterpiece.
//""",
//          imageData: [.init(id: .init(), data: (try? Data(contentsOf: Bundle.main.url(forResource: "burger_bun_05", withExtension: "jpg")!))!)! ]
//        ),
//        .init(
//          id: .init(),
//          description: "Enjoy your beautiful creation!",
//          imageData: [.init(id: .init(), data: (try? Data(contentsOf: Bundle.main.url(forResource: "burger_bun_06", withExtension: "jpg")!))!)! ]
//        )
//      ]),
//      .init(id: .init(), name: "Patties", steps: [
//        .init(id: .init(), description: "Roughly chop all meat into bite size pieces and pass through a meat grinder. It usually helps if the meat is very cold. Frozen meat is better than warm meat, but neither will give you the best result")
//      ]),
//      .init(id: .init(), name: "Toppings", steps: [
//        .init(id: .init(), description: "Prepare the toppings as you like")
//      ]),
//      .init(id: .init(), name: "Ketchup", steps: [
//        .init(id: .init(), description: "In a small saucepan, combine the tomato paste, white vinegar, granulated sugar, salt, onion powder, garlic powder, ground mustard, ground cloves, and water. This magical medley of ingredients is the foundation for creating the most delectable ketchup you've ever tasted. Each ingredient plays a crucial role, adding depth and complexity to the final product that will have you never wanting to go back to store-bought ketchup again."),
//        .init(id: .init(), description: "Place the saucepan on the stovetop over medium heat. As the mixture gently simmers, you can sense the anticipation in the air. The aroma of the ingredients mingling is intoxicating, promising a ketchup that is unlike any other. You're about to witness a transformation that will elevate this humble sauce to new culinary heights."),
//        .init(id: .init(), description: "Stir the mixture occasionally to ensure all the ingredients are well combined. As you stir, you can see the ingredients dancing in the pot, each one contributing its unique flavor to the symphony. The sugar dissolves, adding a touch of sweetness to the tangy tomato paste. The spices unite, infusing the mixture with warmth and aromatic notes that will awaken your taste buds."),
//        .init(id: .init(), description: "Let the mixture simmer for about 15-20 minutes, or until it reaches your desired thickness. The ketchup gradually thickens, and you have the power to determine its consistency. Whether you prefer a pourable ketchup or a thicker, spreadable version, you have full control over its destiny."),
//        .init(id: .init(), description: "Once the ketchup has reached your preferred thickness, remove the saucepan from the heat. The moment of truth has arrived, and you can hardly contain your excitement. As you lift the saucepan from the stove, you can see the richness of the ketchup, and you know that you've created something extraordinary."),
//        .init(id: .init(), description: "Allow the ketchup to cool to room temperature. Patience is key at this stage - giving the ketchup time to cool allows the flavors to meld and harmonize, reaching their full potential. You can't help but smile as you envision the delicious possibilities that await."),
//        .init(id: .init(), description: "Transfer the cooled ketchup to a blender or food processor. It's time to blend this concoction into smooth perfection. As the blades whirl, you can see the texture of the ketchup transform before your eyes. The smoothness is mesmerizing, and you can't resist tasting a spoonful to savor the progress."),
//        .init(id: .init(), description: "Blend the ketchup until it reaches a velvety-smooth consistency. You want the ketchup to be silky and luxurious, gliding effortlessly on your favorite dishes. The blending process creates a harmonious union of flavors, ensuring that each spoonful is a symphony of taste."),
//        .init(id: .init(), description: "Taste the ketchup and adjust the seasoning as needed. This is your moment to fine-tune the flavor to your liking. You might decide to add a pinch more salt for a hint of extra savoriness or a dash of ground cloves for a touch of warmth. Your taste buds are the maestro, guiding this culinary masterpiece to perfection."),
//        .init(id: .init(), description: "Transfer the ketchup to a clean glass jar or container. Your homemade ketchup deserves a special home - a clean, glass jar that will showcase its vibrant color and deliciousness. As you pour the ketchup into the container, you can't help but marvel at how far this humble sauce has come."),
//        .init(id: .init(), description: "Seal the jar and refrigerate the ketchup for at least a few hours before using. This resting period is the final step in creating the most flavorful ketchup imaginable. The flavors continue to develop and intertwine, creating a ketchup that is a symphony of taste and aroma."),
//        .init(id: .init(), description: "Your homemade ketchup is now ready to be savored! Use it as a condiment for fries, burgers, sandwiches, or any dish your heart desires. As you drizzle this exquisite creation on your favorite foods, you'll know that you've achieved ketchup perfection. Your kitchen has become a culinary playground, and you are the master conductor of flavor. Enjoy each spoonful and relish in the knowledge that you've created a ketchup that is truly unparalleled.")
//      ]),
//      .init(id: .init(), name: "Mustard", steps: [
//        .init(id: .init(), description: "In a small bowl, combine the yellow mustard seeds and brown mustard seeds. This delightful combination of seeds will bring a symphony of flavors to your homemade mustard. The boldness of the brown mustard seeds will harmonize with the milder yellow mustard seeds, creating a delightful balance that will tantalize your taste buds with each spoonful."),
//        .init(id: .init(), description: "Add the apple cider vinegar and water to the bowl with the mustard seeds. The addition of apple cider vinegar brings a tangy brightness to the mixture, perfectly complementing the earthy mustard seeds. The water will help soften the seeds and encourage the infusion of flavors, setting the stage for the transformation that is about to unfold."),
//        .init(id: .init(), description: "Stir the mixture to ensure all the seeds are coated with the liquid. As you gently stir the seeds, you can already sense the magic happening - the mustard seeds absorb the liquid, plumping up with anticipation of the flavors that lie ahead. The symphony of textures begins, and you know that this mustard is going to be something truly extraordinary."),
//        .init(id: .init(), description: "Cover the bowl with plastic wrap or a lid, and let it sit at room temperature for at least 24 hours. Patience is the key to creating exceptional mustard. Allowing the mustard seeds to rest and mingle with the liquid for a day allows the flavors to develop and intensify. You can almost hear the seeds whispering to one another, promising to create a masterpiece together."),
//        .init(id: .init(), description: "After 24 hours, the mustard seeds will have absorbed some of the liquid and become plump. You'll notice the transformation as you remove the cover from the bowl - the mustard seeds have become plump with flavor, eagerly awaiting the next step in their journey. This moment is a testament to the power of time and the magic of culinary alchemy."),
//        .init(id: .init(), description: "Transfer the soaked mustard seeds to a blender or food processor. It's time to take this mustard to the next level. By blending the soaked mustard seeds, you'll unleash a symphony of flavors that will dazzle your taste buds. The blender becomes a conductor's baton, orchestrating a harmonious blend of seeds and liquid."),
//        .init(id: .init(), description: "Add honey, salt, turmeric, garlic powder, onion powder, and ground paprika to the blender. These carefully selected ingredients are the secret to creating a mustard that is a true work of art. The honey adds a delicate sweetness that balances the tangy vinegar and the sharp mustard seeds. The salt enhances the flavors, while the turmeric adds a beautiful golden hue that will make your mustard as visually pleasing as it is delicious."),
//        .init(id: .init(), description: "Blend the mixture until you reach your desired consistency. You can make it smooth or leave it slightly grainy, depending on your preference. The blender becomes your magical wand, allowing you to tailor the mustard's texture to your liking. Whether you prefer a velvety-smooth mustard or one with a bit of texture to excite your palate, the choice is yours to make."),
//        .init(id: .init(), description: "If the mustard is too thick, you can add more water to achieve the desired consistency. Don't worry if your mustard turns out thicker than you'd like - a splash of water is all it takes to transform it into the perfect texture. The beauty of homemade mustard lies in its adaptability - you have the power to make it just the way you like it."),
//        .init(id: .init(), description: "Taste the mustard and adjust the seasoning as needed. You can add more salt, honey, or spices to suit your taste. This is the moment when your taste buds take center stage. As you taste the mustard, you become the conductor of its flavor symphony. If you desire a bit more sweetness, add a touch of honey. If you crave more depth, a pinch of salt will do the trick. The power to tailor the flavor to perfection lies in your hands."),
//        .init(id: .init(), description: "Transfer the prepared mustard to a clean jar or container. The moment has come to give your mustard a new home - a clean, empty jar or container. As you pour the mustard into its vessel, you can't help but feel a sense of pride and accomplishment. This creation is the result of your creativity and patience, and it deserves a special place to call its own."),
//        .init(id: .init(), description: "Seal the jar and refrigerate the mustard for at least a day before using. This resting period allows the flavors to meld and develop, resulting in a more flavorful mustard. Waiting is the hardest part, but trust that the magic of time will work wonders. The mustard will continue to evolve, becoming even more complex and irresistible with each passing moment."),
//        .init(id: .init(), description: "Your homemade mustard is now ready to be enjoyed! Use it as a condiment for sandwiches, burgers, hot dogs, or as a dipping sauce for pretzels and other snacks. The moment you've been waiting for has arrived - it's time to savor the fruits of your labor. As you spread the mustard on your favorite sandwich or dip a pretzel into its golden goodness, you'll know that you've created something truly special. Your homemade mustard is more than a condiment; it's a labor of love, a testament to your culinary prowess, and a source of joy with every bite.")
//      ])
//    ]
//  )
//}
//
//
///// TCA God-Feature
///// NavigationTools
/////   1. Tree Navigation
/////   2. Stack Navigation
/////   3. Routing
/////
/////   Combine these with AI to do the following:
/////   1. Onboarding/Demo
/////   2. Finding how to do something / where it is with a demo or path or instant navigation
/////   3. Find settings intelligently
