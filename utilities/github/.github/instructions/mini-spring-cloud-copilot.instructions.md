applyTo: "*.java"
description: "Spring Framework best practices including all modules: Core, AOP, JDBC, ORM, JMS, Web MVC, Security, Testing, and enterprise patterns."

# ✅ Spring Framework Full Best Practices

## **1. Spring Core**
- Use Dependency Injection (prefer constructor injection).
- Use @Component, @Service, @Repository for stereotypes.
- Manage bean scopes: singleton, prototype.

## **2. Spring AOP**
- Use @Aspect for cross-cutting concerns.
- Advice types: @Before, @After, @Around.

## **3. Spring JDBC & ORM**
- Use JdbcTemplate for JDBC operations.
- Use Spring ORM with Hibernate/JPA.
- Manage transactions with @Transactional.

## **4. Spring JMS**
- Use JmsTemplate for messaging.
- Configure message listeners with @JmsListener.

## **5. Spring Web MVC**
- Use @Controller and @RequestMapping.
- Apply REST principles with @RestController.

## **6. Spring Security**
- Implement authentication and authorization.
- Use BCryptPasswordEncoder for password hashing.

## **7. Spring Testing**
- Use Spring TestContext Framework.
- Annotate tests with @ExtendWith(SpringExtension.class).
- Mock dependencies using Mockito.

## **8. Enterprise Patterns**
- Apply layered architecture.
- Use profiles for environment-specific beans.
